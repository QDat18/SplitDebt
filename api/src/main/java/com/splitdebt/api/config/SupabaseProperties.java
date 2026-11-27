/**
 * Trách nhiệm file: Nạp và ánh xạ các thuộc tính cấu hình Supabase Storage từ application.yaml.
 */

package com.splitdebt.api.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "app.supabase")
@Getter
@Setter
public class SupabaseProperties {

    /**
     * URL của dự án Supabase, ví dụ: https://zvgpxmzznstotmqfwjet.supabase.co
     */
    private String url = "https://zvgpxmzznstotmqfwjet.supabase.co";

    /**
     * API Key (Service Role Key hoặc Anon Key có quyền ghi vào Storage)
     */
    private String key = "";

    /**
     * Tên bucket lưu trữ ảnh đại diện (mặc định: Avatar)
     */
    private String bucket = "Avatar";
}
