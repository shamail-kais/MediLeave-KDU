package MediLeave.MediLeave.repository;


import MediLeave.MediLeave.entity.LeaveDocument;
import MediLeave.MediLeave.entity.LeaveRequest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LeaveDocumentRepository extends JpaRepository<LeaveDocument, Long> {
    List<LeaveDocument> findByLeaveRequest(LeaveRequest leaveRequest);
}