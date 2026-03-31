package MediLeave.MediLeave.controller;


import MediLeave.MediLeave.dto.AuthResponse;
import MediLeave.MediLeave.dto.LoginRequest;
import MediLeave.MediLeave.dto.RegisterRequest;
import MediLeave.MediLeave.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor

public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        authService.registerStudent(request);
        return ResponseEntity.ok("Student registered successfully");
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }
}