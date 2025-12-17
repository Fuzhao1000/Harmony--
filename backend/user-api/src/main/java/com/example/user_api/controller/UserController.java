package com.example.user_api.controller;

import com.example.user_api.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import com.example.user_api.entity.User;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("/api")

public class UserController {

    @Autowired
    private UserService userService;
    private static final Logger logger = LoggerFactory.getLogger(UserController.class);
    @PostMapping("/register")
    public Map<String, Object> register(@RequestBody RegisterBody body) {

        boolean success = userService.register(body.getPhone(), body.getPassword());

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", success ? "注册成功" : "手机号已存在");
        return result;
    }
    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody RegisterBody body) {

        Map<String, Object> res = new HashMap<>();

        User user = userService.login(body.getPhone(), body.getPassword());
        logger.info("登录请求 phone={} password={}", body.getPhone(), body.getPassword());
        logger.info("返回的用户对象: {}", user);

        if (user == null) {
            res.put("success", false);
            res.put("message", "手机号或密码错误");
        } else {
            res.put("success", true);
            res.put("message", "登录成功");
            res.put("id", user.getId());    // ✅ 返回用户ID
            res.put("name", user.getName()); // ✅ 返回用户名
            logger.info("返回的用户 id={} name={}", user.getId(), user.getName());
        }

        return res;
    }
    @PostMapping("/updateName")
    public Map<String, Object> updateName(@RequestBody Map<String, String> body) {
        Long id = Long.parseLong(body.get("id"));
        String name = body.get("name");

        Map<String, Object> res = new HashMap<>();

        boolean ok = userService.updateName(id, name);
        res.put("success", ok);
        return res;
    }

}
