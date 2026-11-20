<?php
/**
 * Plugin Name: BSR Push
 * Description: নতুন পোস্ট পাবলিশ (বা শিডিউল পাবলিশ) হলে BSR অ্যাপে Firebase (FCM HTTP v1) দিয়ে অটো পুশ নোটিফিকেশন পাঠায়।
 * Version: 1.0.0
 * Requires PHP: 7.4
 */
if (!defined('ABSPATH')) exit;

class BSR_Push {
    const OPT = 'bsr_push_sa';        // সার্ভিস অ্যাকাউন্ট JSON
    const LAST = 'bsr_push_last';     // শেষ ফলাফল

    public function __construct() {
        add_action('transition_post_status', [$this, 'on_status'], 10, 3);
        add_action('bsr_push_send', [$this, 'send_post'], 10, 1);
        add_action('admin_menu', [$this, 'menu']);
        add_action('admin_post_bsr_push_save', [$this, 'save']);
        add_action('admin_post_bsr_push_test', [$this, 'test']);
    }

    /* ---------- ট্রিগার ---------- */
    public function on_status($new, $old, $post) {
        if ($new !== 'publish' || $old === 'publish' || $post->post_type !== 'post') return;
        if (get_post_meta($post->ID, '_bsr_pushed', true)) return; // একবারই
        update_post_meta($post->ID, '_bsr_pushed', time());
        // টার্ম/ছবি সেভ হওয়ার পর পাঠাতে আলাদা ইভেন্ট
        wp_schedule_single_event(time(), 'bsr_push_send', [$post->ID]);
        spawn_cron();
    }

    public function send_post($id) {
        $post = get_post($id);
        if (!$post || $post->post_status !== 'publish') return;

        $cond = "'all' in topics";
        foreach (array_slice(wp_get_post_categories($id), 0, 4) as $cid) { // FCM কন্ডিশনে সর্বোচ্চ ৫ টপিক
            $cond .= " || 'cat_" . intval($cid) . "' in topics";
        }
        $body = wp_trim_words(wp_strip_all_tags(strip_shortcodes($post->post_excerpt ?: $post->post_content)), 25, '…');
        $msg = [
            'condition'    => $cond,
            'notification' => array_filter([
                'title' => html_entity_decode(get_the_title($id), ENT_QUOTES, 'UTF-8'),
                'body'  => $body,
                'image' => get_the_post_thumbnail_url($id, 'medium_large') ?: null,
            ]),
            'data'    => ['post_id' => (string) $id, 'link' => get_permalink($id)],
            'android' => ['priority' => 'HIGH'],
            'apns'    => ['headers' => ['apns-priority' => '10'], 'payload' => ['aps' => ['sound' => 'default']]],
        ];
        $this->fcm($msg);
    }

    /* ---------- FCM ---------- */
    private function sa() {
        $j = json_decode((string) get_option(self::OPT), true);
        return (is_array($j) && !empty($j['client_email']) && !empty($j['private_key']) && !empty($j['project_id'])) ? $j : null;
    }

    private function b64($s) { return rtrim(strtr(base64_encode($s), '+/', '-_'), '='); }

    private function token($sa) {
        $t = get_transient('bsr_push_token');
        if ($t) return $t;
        $now = time();
        $h = $this->b64(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $c = $this->b64(json_encode([
            'iss' => $sa['client_email'], 'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token', 'iat' => $now, 'exp' => $now + 3600,
        ]));
        $sig = '';
        if (!openssl_sign("$h.$c", $sig, $sa['private_key'], OPENSSL_ALGO_SHA256)) return null;
        $r = wp_remote_post('https://oauth2.googleapis.com/token', ['timeout' => 15, 'body' => [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion' => "$h.$c." . $this->b64($sig),
        ]]);
        if (is_wp_error($r)) return null;
        $d = json_decode(wp_remote_retrieve_body($r), true);
        if (empty($d['access_token'])) return null;
        set_transient('bsr_push_token', $d['access_token'], 3000);
        return $d['access_token'];
    }

    private function fcm(array $message) {
        $sa = $this->sa();
        if (!$sa) { update_option(self::LAST, 'সার্ভিস অ্যাকাউন্ট সেট করা নেই'); return false; }
        $tok = $this->token($sa);
        if (!$tok) { update_option(self::LAST, 'অ্যাক্সেস টোকেন পাওয়া যায়নি (কী/OpenSSL চেক করুন)'); return false; }
        $r = wp_remote_post("https://fcm.googleapis.com/v1/projects/{$sa['project_id']}/messages:send", [
            'timeout' => 15,
            'headers' => ['Authorization' => "Bearer $tok", 'Content-Type' => 'application/json'],
            'body'    => wp_json_encode(['message' => $message]),
        ]);
        $code = is_wp_error($r) ? 0 : wp_remote_retrieve_response_code($r);
        update_option(self::LAST, current_time('mysql') . ' — HTTP ' . $code . ' ' . (is_wp_error($r) ? $r->get_error_message() : wp_remote_retrieve_body($r)));
        return $code === 200;
    }

    /* ---------- অ্যাডমিন পেজ ---------- */
    public function menu() {
        add_options_page('BSR Push', 'BSR Push', 'manage_options', 'bsr-push', [$this, 'page']);
    }

    public function page() {
        if (!current_user_can('manage_options')) return;
        $sa = $this->sa(); ?>
        <div class="wrap"><h1>BSR Push নোটিফিকেশন</h1>
        <p>অবস্থা: <strong><?php echo $sa ? 'সংযুক্ত (প্রজেক্ট: ' . esc_html($sa['project_id']) . ')' : 'সেট করা নেই'; ?></strong></p>
        <form method="post" action="<?php echo esc_url(admin_url('admin-post.php')); ?>">
            <?php wp_nonce_field('bsr_push_save'); ?><input type="hidden" name="action" value="bsr_push_save">
            <p>Firebase সার্ভিস অ্যাকাউন্ট JSON (Project settings → Service accounts → Generate new private key):</p>
            <textarea name="sa" rows="8" class="large-text code" placeholder='{"type":"service_account", ...}'></textarea>
            <p class="description">নিরাপত্তার জন্য সেভ করা কী এখানে দেখানো হয় না। নতুন JSON দিলে আগেরটি বদলে যাবে।</p>
            <?php submit_button('সেভ'); ?>
        </form>
        <form method="post" action="<?php echo esc_url(admin_url('admin-post.php')); ?>">
            <?php wp_nonce_field('bsr_push_test'); ?><input type="hidden" name="action" value="bsr_push_test">
            <?php submit_button('টেস্ট নোটিফিকেশন পাঠান', 'secondary'); ?>
        </form>
        <p>শেষ ফলাফল: <code><?php echo esc_html((string) get_option(self::LAST, '—')); ?></code></p></div>
    <?php }

    public function save() {
        if (!current_user_can('manage_options')) wp_die('Forbidden');
        check_admin_referer('bsr_push_save');
        $raw = wp_unslash($_POST['sa'] ?? '');
        $j = json_decode($raw, true);
        if (is_array($j) && !empty($j['client_email']) && !empty($j['private_key']) && !empty($j['project_id'])) {
            update_option(self::OPT, $raw, false); // autoload বন্ধ
            delete_transient('bsr_push_token');
        }
        wp_safe_redirect(admin_url('options-general.php?page=bsr-push')); exit;
    }

    public function test() {
        if (!current_user_can('manage_options')) wp_die('Forbidden');
        check_admin_referer('bsr_push_test');
        $this->fcm([
            'topic' => 'all',
            'notification' => ['title' => 'BSR টেস্ট', 'body' => 'নোটিফিকেশন সফলভাবে কাজ করছে ✅'],
        ]);
        wp_safe_redirect(admin_url('options-general.php?page=bsr-push')); exit;
    }
}
new BSR_Push();
