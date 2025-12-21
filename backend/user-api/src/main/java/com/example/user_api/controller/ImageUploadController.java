package com.example.user_api.controller;

import com.example.user_api.config.UploadProperties;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/upload")
public class ImageUploadController {

    private final String uploadPath;

    // 构造函数注入配置属性
    public ImageUploadController(UploadProperties properties) {
        String path = properties.getPath();

        // 归一化路径（确保以分隔符结尾）
        String normalizedPath = path.endsWith(File.separator) ? path : path + File.separator;

        // 创建目录
        File dir = new File(normalizedPath);
        if (!dir.exists()) {
            if (!dir.mkdirs()) {
                System.err.println("警告：上传目录创建失败，请检查权限: " + normalizedPath);
            } else {
                System.out.println("上传目录创建成功: " + normalizedPath);
            }
        }

        // 只赋值一次
        this.uploadPath = normalizedPath;
    }

    @PostMapping("/image")
    public Map<String, Object> uploadImage(@RequestParam("file") MultipartFile file) {
        Map<String, Object> result = new HashMap<>();

        try {
            if (file.isEmpty()) {
                result.put("success", false);
                result.put("message", "文件为空");
                return result;
            }

            String originalFilename = file.getOriginalFilename();
            if (originalFilename == null) {
                result.put("success", false);
                result.put("message", "文件名无效");
                return result;
            }

            String filename = UUID.randomUUID() + "_" + originalFilename;
            File dest = new File(uploadPath + filename);

            file.transferTo(dest);

            String imageUrl = "/images/" + filename;

            result.put("success", true);
            result.put("url", imageUrl);

        } catch (IOException e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "保存失败: " + e.getMessage());
        }

        return result;
    }
}