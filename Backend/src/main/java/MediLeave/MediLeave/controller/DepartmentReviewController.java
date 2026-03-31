package MediLeave.MediLeave.controller;

import MediLeave.MediLeave.dto.LeaveDecisionRequest;
import MediLeave.MediLeave.dto.LeaveRequestResponse;
import MediLeave.MediLeave.security.AuthUser;
import MediLeave.MediLeave.service.DepartmentReviewService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/department")
@RequiredArgsConstructor
public class DepartmentReviewController {

    private final DepartmentReviewService departmentReviewService;

    @GetMapping("/requests")
    public ResponseEntity<List<LeaveRequestResponse>> verifiedRequests() {
        return ResponseEntity.ok(departmentReviewService.getVerifiedRequests());
    }

    @PutMapping("/requests/{id}/approve")
    public ResponseEntity<LeaveRequestResponse> approve(@PathVariable Long id,
                                                        @Valid @RequestBody LeaveDecisionRequest request,
                                                        Authentication authentication) {
        AuthUser authUser = (AuthUser) authentication.getPrincipal();
        return ResponseEntity.ok(departmentReviewService.approve(authUser, id, request));
    }

    @PutMapping("/requests/{id}/reject")
    public ResponseEntity<LeaveRequestResponse> reject(@PathVariable Long id,
                                                       @Valid @RequestBody LeaveDecisionRequest request,
                                                       Authentication authentication) {
        AuthUser authUser = (AuthUser) authentication.getPrincipal();
        return ResponseEntity.ok(departmentReviewService.reject(authUser, id, request));
    }

    @GetMapping("/requests/history")
    public ResponseEntity<List<LeaveRequestResponse>> myHistory() {
        return ResponseEntity.ok(departmentReviewService.getProcessedRequests());
    }
}
