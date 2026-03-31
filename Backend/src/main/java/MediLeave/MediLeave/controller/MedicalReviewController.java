package MediLeave.MediLeave.controller;


import MediLeave.MediLeave.dto.LeaveDecisionRequest;
import MediLeave.MediLeave.dto.LeaveRequestResponse;
import MediLeave.MediLeave.security.AuthUser;
import MediLeave.MediLeave.service.MedicalReviewService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/medical")
@RequiredArgsConstructor
public class MedicalReviewController {

    private final MedicalReviewService medicalReviewService;

    @GetMapping("/requests")
    public ResponseEntity<List<LeaveRequestResponse>> submittedRequests() {
        return ResponseEntity.ok(medicalReviewService.getSubmittedRequests());
    }

    @PutMapping("/requests/{id}/verify")
    public ResponseEntity<LeaveRequestResponse> verify(@PathVariable Long id,
                                                       @Valid @RequestBody LeaveDecisionRequest request,
                                                       Authentication authentication) {
        AuthUser authUser = (AuthUser) authentication.getPrincipal();
        return ResponseEntity.ok(medicalReviewService.verifyRequest(authUser, id, request));
    }

    @PutMapping("/requests/{id}/reject")
    public ResponseEntity<LeaveRequestResponse> reject(@PathVariable Long id,
                                                       @Valid @RequestBody LeaveDecisionRequest request,
                                                       Authentication authentication) {
        AuthUser authUser = (AuthUser) authentication.getPrincipal();
        return ResponseEntity.ok(medicalReviewService.rejectRequest(authUser, id, request));
    }

    @GetMapping("/requests/history")
    public ResponseEntity<List<LeaveRequestResponse>> history() {
        return ResponseEntity.ok(medicalReviewService.getProcessedRequests());
    }
}