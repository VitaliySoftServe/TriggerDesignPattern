public with sharing class WorkOrderImportModel {
    public class WorkOrderExcel {
        @AuraEnabled
        public String FakeId {
            get; set;
        }
        @AuraEnabled
        public String PropertyId {
            get; set;
        }
        @AuraEnabled
        public String CallerName {
            get; set;
        }
        @AuraEnabled
        public String CallerPhone {
            get; set;
        }
        @AuraEnabled
        public String CallerEmail {
            get; set;
        }
        public Id NewPropertyId {
            get; set;
        }
        public Id ContactId {
            get; set;
        }
        public String validate() {
            if (PropertyId == null)
                return 'PropertyId';
            if (CallerName == null)
                return 'Caller Name';
            if (CallerPhone == null)
                return 'Caller Phone';
            if (CallerEmail == null)
                return 'Caller Email';
            return null;
        }
    }

    public class WorkOrderLineItemExcel {
        @AuraEnabled
        public String FakeId {
            get; set;
        }
        @AuraEnabled
        public String Category {
            get; set;
        }
        @AuraEnabled
        public String SubCategory {
            get; set;
        }
        @AuraEnabled
        public String Issue {
            get; set;
        }
        @AuraEnabled
        public String ProblemDescription {
            get; set;
        }
        @AuraEnabled
        public String YardiWorkOrderNumber {
            get; set;
        }
        public String validate() {
            if (Category == null)
                return 'Category';
            if (SubCategory == null)
                return 'SubCategory';
            if (Issue == null)
                return 'Issue';
            if (YardiWorkOrderNumber == null)
                return 'Yardi Work Order Number';
            return null;
        }
    }

    public class ServiceAppointmentExcel {
        @AuraEnabled
        public String FakeId {
            get;

            set;
        }
        @AuraEnabled
        public String VendorId {
            get; set;
        }
        @AuraEnabled
        public String EmployeeCode {
            get; set;
        }
        @AuraEnabled
        public String Status {
            get; set;
        }
        @AuraEnabled
        public String ScheduledStartDate {
            get; set;
        }
        @AuraEnabled
        public String ScheduledFinishDate {
            get; set;
        }
        @AuraEnabled
        public String ScheduledStartTime {
            get; set;
        }
        @AuraEnabled
        public String ScheduledFinishTime {
            get; set;
        }
        public String validate() {
            if (VendorId == null)
                return 'Vendor ID';
            if (EmployeeCode == null)
                return 'Employee Code';
            if (Status == null)
                return 'Status';
            if (ScheduledStartDate == null)
                return 'Scheduled Start Date';
            if (ScheduledFinishDate == null)
                return 'Scheduled Finish Date';
            if (ScheduledStartTime == null)
                return 'Scheduled Start Time';
            if (ScheduledFinishTime == null)
                return 'Scheduled Finish Time';
            return null;
        }
    }

    @AuraEnabled
    public List<WorkOrderExcel> WorkOrders {
        get; set;
    }
    @AuraEnabled
    public List<WorkOrderLineItemExcel> WorkOrderLineItems {
        get; set;
    }
    @AuraEnabled
    public List<ServiceAppointmentExcel> ServiceAppointments {
        get; set;
    }
    public String validate() {
        if (WorkOrders == null || WorkOrders.size() < 1) {
            return 'No Work Orders data was found in spreadsheet.';
        }
        if (WorkOrderLineItems == null || WorkOrderLineItems.size() < 1) {
            return 'No Work Order Line Items data was found in spreadsheet.';
        }
        if (ServiceAppointments == null || ServiceAppointments.size() < 1) {
            return 'No Service Appointments data was found in spreadsheet.';
        }
        String message;
        for (WorkOrderExcel w : WorkOrders) {
            message = w.validate();
            if (message != null) {
                return String.format(
                    'At least one data is missing, required field: "{0}", ' +
                    'in line {1}',
                    new List<String> { message, w.FakeId }
                    );
            }
        }
        for (WorkOrderLineItemExcel w : WorkOrderLineItems) {
            message = w.validate();
            if (message != null) {
                return String.format(
                    'At least one Work Order Line Item is missing, ' +
                    'required field: "{0}", in line {1}',
                    new List<String> { message, w.FakeId }
                    );
            }
        }
        for (ServiceAppointmentExcel s : ServiceAppointments) {
            message = s.validate();
            if (message != null) {
                return String.format(
                    'At least one Service Appointment is missing, ' +
                    'required field: "{0}", in line {1}',
                    new List<String> { message, s.FakeId }
                    );
            }
        }
        return null;
    }
}