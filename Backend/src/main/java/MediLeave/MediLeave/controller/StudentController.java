package MediLeave.MediLeave.controller;

import MediLeave.MediLeave.dto.LeaveRequestCreateRequest;
import MediLeave.MediLeave.dto.LeaveRequestResponse;
import MediLeave.MediLeave.dto.UserResponse;
import MediLeave.MediLeave.security.AuthUser;
import MediLeave.MediLeave.service.StudentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/student")
@RequiredArgsConstructor
public class StudentController {

    private final StudentService studentService;

    @GetMapping("/me")
    public ResponseEntity<UserResponse> me(Authentication authentication) {
        AuthUser authUser = (AuthUser) authentication.getPrincipal();
        return ResponseEntity.ok(studentService.getProfile(authUser));
    }

    @PostMapping(value = "/leave-requests", consumes = {"multipart/form-data"})
    public ResponseEntity<LeaveRequestResponse> createLeaveRequest(
            @Valid @ModelAttribute LeaveRequestCreateRequest request,
            @RequestPart(value = "files", required = false) List<MultipartFile> files,
            Authentication authentication) {

        AuthUser authUser = (AuthUser) authentication.getPrincipal();
        return ResponseEntity.ok(studentService.createLeaveRequest(authUser, request, files));
    }

    @GetMapping("/leave-requests")
    public ResponseEntity<List<LeaveRequestResponse>> myRequests(Authentication authentication) {
        AuthUser authUser = (AuthUser) authentication.getPrincipal();
        return ResponseEntity.ok(studentService.getMyRequests(authUser));
    }

    @GetMapping("/leave-requests/{id}")
    public ResponseEntity<LeaveRequestResponse> myRequest(@PathVariable Long id,
                                                          Authentication authentication) {
        AuthUser authUser = (AuthUser) authentication.getPrincipal();
        return ResponseEntity.ok(studentService.getMyRequest(authUser, id));
    }
}
