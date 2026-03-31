package MediLeave.MediLeave.controller;

import MediLeave.MediLeave.dto.CreateDepartmentRequest;
import MediLeave.MediLeave.dto.CreateStaffRequest;
import MediLeave.MediLeave.dto.UserResponse;
import MediLeave.MediLeave.entity.Department;
import MediLeave.MediLeave.entity.LeaveRequest;
import MediLeave.MediLeave.service.AdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    @PostMapping("/staff")
    public ResponseEntity<?> createStaff(@Valid @RequestBody CreateStaffRequest request) {
        adminService.createStaff(request);
        return ResponseEntity.ok("Staff user created successfully");
    }

    @PostMapping("/departments")
    public ResponseEntity<Department> createDepartment(@Valid @RequestBody CreateDepartmentRequest request) {
        return ResponseEntity.ok(adminService.createDepartment(request));
    }

    @GetMapping("/departments")
    public ResponseEntity<List<Department>> getDepartments() {
        return ResponseEntity.ok(adminService.getAllDepartments());
    }

    @GetMapping("/users")
    public ResponseEntity<List<UserResponse>> users() {
        return ResponseEntity.ok(adminService.getAllUsers());
    }

    @GetMapping("/requests")
    public ResponseEntity<List<LeaveRequest>> requests() {
        return ResponseEntity.ok(adminService.getAllRequests());
    }
}