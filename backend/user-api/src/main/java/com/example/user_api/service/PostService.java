package com.example.user_api.service;

import com.example.user_api.entity.Post;
import com.example.user_api.repository.PostRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PostService {

    @Autowired
    private PostRepository postRepository;

    public Post publish(Post post) {
        post.setCreateTime(System.currentTimeMillis());
        return postRepository.save(post);
    }

    public List<Post> findAll() {
        return postRepository.findAll();
    }

    public List<Post> findByBaname(String baname) {
        return postRepository.findByBaname(baname);
    }

}
