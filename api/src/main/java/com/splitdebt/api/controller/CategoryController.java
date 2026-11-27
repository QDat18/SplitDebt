package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.repository.CategoryRepository;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/categories")
public class CategoryController {
    private final CategoryRepository repository;
    public CategoryController(CategoryRepository repository) { this.repository = repository; }
    public record CategoryOption(Long id, String name) {}
    @GetMapping
    public ApiResponse<List<CategoryOption>> list() {
        return ApiResponse.ok(repository.findAll(org.springframework.data.domain.Sort.by("name")).stream().map(c -> new CategoryOption(c.getId(), c.getName())).toList());
    }
}
