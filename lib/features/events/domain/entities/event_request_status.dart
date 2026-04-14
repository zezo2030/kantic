// Event Request Status - Domain Layer
enum EventRequestStatus {
  draft,
  submitted,
  underReview,
  quoted,
  invoiced,
  depositPaid,
  paid,
  confirmed,
  rejected;

  static EventRequestStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return EventRequestStatus.draft;
      case 'submitted':
        return EventRequestStatus.submitted;
      case 'under_review':
        return EventRequestStatus.underReview;
      case 'quoted':
        return EventRequestStatus.quoted;
      case 'invoiced':
        return EventRequestStatus.invoiced;
      case 'deposit_paid':
        return EventRequestStatus.depositPaid;
      case 'paid':
        return EventRequestStatus.paid;
      case 'paid_and_completed':
      case 'confirmed':
        return EventRequestStatus.confirmed;
      case 'rejected':
        return EventRequestStatus.rejected;
      default:
        return EventRequestStatus.draft;
    }
  }

  String toApiString() {
    switch (this) {
      case EventRequestStatus.draft:
        return 'draft';
      case EventRequestStatus.submitted:
        return 'submitted';
      case EventRequestStatus.underReview:
        return 'under_review';
      case EventRequestStatus.quoted:
        return 'quoted';
      case EventRequestStatus.invoiced:
        return 'invoiced';
      case EventRequestStatus.depositPaid:
        return 'deposit_paid';
      case EventRequestStatus.paid:
        return 'paid';
      case EventRequestStatus.confirmed:
        return 'confirmed';
      case EventRequestStatus.rejected:
        return 'rejected';
    }
  }

  String getDisplayName() {
    switch (this) {
      case EventRequestStatus.draft:
        return 'مسودة';
      case EventRequestStatus.submitted:
        return 'تم الإرسال';
      case EventRequestStatus.underReview:
        return 'قيد المراجعة';
      case EventRequestStatus.quoted:
        return 'تم التسعير';
      case EventRequestStatus.invoiced:
        return 'تم إصدار الفاتورة';
      case EventRequestStatus.depositPaid:
        return 'تم دفع العربون';
      case EventRequestStatus.paid:
        return 'تم الدفع';
      case EventRequestStatus.confirmed:
        return 'مؤكد';
      case EventRequestStatus.rejected:
        return 'مرفوض';
    }
  }
}
