package MediLeave.MediLeave.repository;



import MediLeave.MediLeave.entity.LeaveRequest;
import MediLeave.MediLeave.entity.LeaveStatus;
import MediLeave.MediLeave.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LeaveRequestRepository extends JpaRepository<LeaveRequest, Long> {
    List<LeaveRequest> findByStudentOrderBySubmittedAtDesc(User student);
    List<LeaveRequest> findByStatusOrderBySubmittedAtDesc(LeaveStatus status);
    List<LeaveRequest> findByMedicalReviewerOrderBySubmittedAtDesc(User medicalReviewer);
    List<LeaveRequest> findByDepartmentReviewerOrderBySubmittedAtDesc(User departmentReviewer);
}