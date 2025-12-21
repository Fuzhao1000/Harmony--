package com.example.user_api.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "upload")
public class UploadProperties {

    private String path = "C:/uploads/images/";  // 默认值

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }
}