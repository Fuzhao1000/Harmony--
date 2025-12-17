package com.example.user_api.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {

        http
                // ✅ 关闭 CSRF（前后端分离必须关）
                .csrf(AbstractHttpConfigurer::disable)

                // ✅ 授权规则（使用 lambda）
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/register").permitAll()   // 放行注册
                        .anyRequest().permitAll()                       // 其他接口全部放行
                )

                // ✅ 关闭默认登录表单
                .formLogin(AbstractHttpConfigurer::disable)

                // ✅ 关闭 HTTP Basic
                .httpBasic(AbstractHttpConfigurer::disable)

                // ✅ 关闭注销功能
                .logout(AbstractHttpConfigurer::disable);

        return http.build();
    }
}
