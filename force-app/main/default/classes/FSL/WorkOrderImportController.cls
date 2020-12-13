public with sharing class WorkOrderImportController {
    private static List<ErrorEntity> errorsToFrontList = new List<ErrorEntity>();
    private static Savepoint sp;
    @AuraEnabled(cacheable = false)
    public static String importWorkOrder(WorkOrderImportModel workOrderData) {
        System.debug(workOrderData);
        sp = Database.setSavepoint();
        validateWorkOrderData(workOrderData);
        List<WorkOrderImportModel.WorkOrderExcel> workOrdersWithPropertyIds =
            addWorkOrderPropertyIds(workOrderData.WorkOrders);
        if (checkErrorsToFront(errorsToFrontList)) {
            return JSON.serialize(errorsToFrontList);
        }
        if (workOrdersWithPropertyIds == null) {
            throw new AuraHandledException('One or more PropertyIds are missing in Database');
        }
        List<WorkOrderImportModel.WorkOrderExcel> workOrdersWithPropertyIdsAndContactIdsExcel =
            addWorkOrderContactIds(workOrdersWithPropertyIds);
        if (checkErrorsToFront(errorsToFrontList)) {
            return JSON.serialize(errorsToFrontList);
        }
        if (workOrdersWithPropertyIdsAndContactIdsExcel == null) {
            throw new AuraHandledException('One or more Caller Emails or Caller Phones are missing in Database');
        }
        List<WorkOrderImportModel.WorkOrderExcel> validatedAndPreparedWorkOrders =
            validateWorkOrders(workOrdersWithPropertyIdsAndContactIdsExcel);
        if (checkErrorsToFront(errorsToFrontList)) {
            return JSON.serialize(errorsToFrontList);
        }
        if (validatedAndPreparedWorkOrders == null) {
            throw new AuraHandledException('Some errors occured trying to create Work Orders. Check provided data');
        }
        List<Id> dbWorkOrderExcelAmountIds = createWorkOrders (
            validatedAndPreparedWorkOrders,
            workOrdersWithPropertyIdsAndContactIdsExcel
            );
        if (checkErrorsToFront(errorsToFrontList)) {
            return JSON.serialize(errorsToFrontList);
        }
        if (dbWorkOrderExcelAmountIds == null) {
            throw new AuraHandledException('Problem occured during creating Work Orders');
        }
        List<Id> dbWorkOrderLineItemIds = createWorkOrderLineItems (
            workOrderData.WorkOrderLineItems,
            dbWorkOrderExcelAmountIds
            );
        if (checkErrorsToFront(errorsToFrontList)) {
            return JSON.serialize(errorsToFrontList);
        }
        if (dbWorkOrderLineItemIds == null) {
            throw new AuraHandledException('Problem occured during creating Work Order Line Items');
        }
        List<Id> serviceAppointmentIds = createServiceAppointments (
            workOrderData.ServiceAppointments,
            dbWorkOrderLineItemIds
            );
        if (checkErrorsToFront(errorsToFrontList)) {
            return JSON.serialize(errorsToFrontList);
        }
        if (serviceAppointmentIds == null) {
            throw new AuraHandledException('Problem occured during creating Service Appointments');
        }
        return null;
    }

    private static List<WorkOrderImportModel.WorkOrderExcel> addWorkOrderPropertyIds (
        List<WorkOrderImportModel.WorkOrderExcel> workOrderExcelList
        ) {
        Set <String> oldPropertyIdSet = new Set<String>();
        for (WorkOrderImportModel.WorkOrderExcel w : workOrderExcelList) {
            oldPropertyIdSet.add(w.PropertyId);
        }
        List<Property__c> properties = [SELECT Yardi_Property_ID__c
                                        FROM Property__c
                                        WHERE Yardi_Property_ID__c IN :oldPropertyIdSet];
        Map<String, Id> propertyYardiIdMap = new Map<String, Id>();
        for (Property__c p : properties) {
            propertyYardiIdMap.put(p.Yardi_Property_ID__c, p.Id);
        }
        if (propertyYardiIdMap.keyset().size() < oldPropertyIdSet.size()) {
            for (String pId : propertyYardiIdMap.keyset()) {
                if (oldPropertyIdSet.contains(pId)) {
                    oldPropertyIdSet.remove(pId);
                }
            }
            for (WorkOrderImportModel.WorkOrderExcel w : workOrderExcelList) {
                if (oldPropertyIdSet.contains(w.PropertyId)) {
                    ErrorEntity e = new ErrorEntity('1',
                                                    w.FakeId,
                                                    new List<String>
                                                    {'This PropertyId is missing in the DB'});
                    errorsToFrontList.add(e);
                }
            }
            return null;
        }
        for (WorkOrderImportModel.WorkOrderExcel w : workOrderExcelList) {
            if (propertyYardiIdMap.keyset().contains(w.PropertyId)) {
                w.NewPropertyId = propertyYardiIdMap.get(w.PropertyId);
            }
        }
        return workOrderExcelList;
    }

    private static List<WorkOrderImportModel.WorkOrderExcel> addWorkOrderContactIds (
        List<WorkOrderImportModel.WorkOrderExcel> workOrderExcelList
        ) {
        Set<String> excelEmails = new Set<String>();
        Set<String> excelPhones = new Set<String>();
        for (WorkOrderImportModel.WorkOrderExcel w : workOrderExcelList) {
            excelEmails.add(w.CallerEmail);
            excelPhones.add(w.CallerPhone);
        }
        List<Contact> contactsWithEmails = [SELECT Email
                                            FROM Contact
                                            WHERE Email IN :excelEmails];
        List<Contact> contactsWithPhones = [SELECT Phone
                                            FROM Contact
                                            WHERE Phone IN :excelPhones];
        Map<String, Id> emailsAndIdMap = new Map<String, Id>();
        for (Contact c : contactsWithEmails) {
            emailsAndIdMap.put(c.Email, c.Id);
        }
        Map<String, Id> phonesAndIdMap = new Map<String, Id>();
        for (Contact p : contactsWithPhones) {
            phonesAndIdMap.put(p.Phone, p.Id);
        }
        for (WorkOrderImportModel.WorkOrderExcel wOrder : workOrderExcelList) {
            if (!emailsAndIdMap.keySet().contains(wOrder.CallerEmail) &&
                !phonesAndIdMap.keySet().contains(wOrder.CallerPhone)) {
                ErrorEntity e = new ErrorEntity('1',
                                                wOrder.FakeId,
                                                new List<String>
                                                {'Both Caller Email and Caller Phone are missing  in the DB'});
                errorsToFrontList.add(e);
            }
        }
        if (checkErrorsToFront(errorsToFrontList)) {
            return null;
        }
        for (WorkOrderImportModel.WorkOrderExcel wOrder : workOrderExcelList) {
            if (emailsAndIdMap.containskey(wOrder.CallerEmail)) {
                wOrder.ContactId = emailsAndIdMap.get(wOrder.CallerEmail);
            } else if (phonesAndIdMap.containskey(wOrder.CallerPhone)) {
                wOrder.ContactId = phonesAndIdMap.get(wOrder.CallerPhone);
            } else {
                ErrorEntity e = new ErrorEntity('1',
                                                wOrder.FakeId,
                                                new List<String>
                                                {'Problem with Caller Email and/or Caller Phone'});
                errorsToFrontList.add(e);
            }
        }
        if (checkErrorsToFront(errorsToFrontList)) {
            return null;
        }
        return workOrderExcelList;
    }

    private static List<WorkOrderImportModel.WorkOrderExcel> validateWorkOrders (
        List<WorkOrderImportModel.WorkOrderExcel> workOrderExcelList
        ) {
        Set <String> oldPropertyIdSet = new Set<String>();
        for (WorkOrderImportModel.WorkOrderExcel wOrderExcel : workOrderExcelList) {
            Integer i = 0;
            oldPropertyIdSet.add(wOrderExcel.PropertyId);
            for (WorkOrderImportModel.WorkOrderExcel wo : workOrderExcelList) {
                if (wOrderExcel.PropertyId == wo.PropertyId &&
                    wOrderExcel.ContactId != wo.ContactId) {
                    i++;
                }
            }
            if (i > 0) {
                ErrorEntity e = new ErrorEntity('1',
                                                wOrderExcel.FakeId,
                                                new List<String>
                                                {'It can not be the same PropetyId but ' +
                                                 'different Contact details (Phone, Email)'});
                errorsToFrontList.add(e);
            }
        }
        if (checkErrorsToFront(errorsToFrontList)) {
            return null;
        }
        List<WorkOrderImportModel.WorkOrderExcel> validatedAndPreparedWorkOrders =
            new List<WorkOrderImportModel.WorkOrderExcel>();
        for (WorkOrderImportModel.WorkOrderExcel w : workOrderExcelList) {
            if (oldPropertyIdSet.contains(w.PropertyId)) {
                validatedAndPreparedWorkOrders.add(w);
                oldPropertyIdSet.remove(w.PropertyId);
            }
        }
        return validatedAndPreparedWorkOrders;
    }

    private static List<Id> createWorkOrders (
        List<WorkOrderImportModel.WorkOrderExcel> properWorkOrdersToDb,
        List<WorkOrderImportModel.WorkOrderExcel> workOrderExcelList
        ) {
        List<WorkOrder> workOrders = new List<WorkOrder>();
        List<Case> cases = new List<Case>();
        RecordType recType = [SELECT Id FROM RecordType
                              WHERE DeveloperName = 'TenantIssue'
                                                    AND IsActive = True
                                                                   AND SobjectType = 'Case'];
        for (WorkOrderImportModel.WorkOrderExcel w : properWorkOrdersToDb) {
            try {
                Case c = new Case(
                    ContactId = w.ContactId,
                    Origin = FslConstants.COMMUNITY,
                    Priority = FslConstants.MEDIUM_PRIORITY,
                    Reason = FslConstants.ISSUE_SUBMISSION,
                    RecordTypeId = recType.Id,
                    Status = FslConstants.NEW_STATUS,
                    Type = FslConstants.SERVICE_REQUEST
                    );
                cases.add(c);
                WorkOrder wOrder = new WorkOrder(
                    ContactId = w.ContactId,
                    PropertyId__c = w.NewPropertyId
                    );
                workOrders.add(wOrder);
            }
            catch (Exception ex) {
                throw new AuraHandledException(
                          String.format(
                              '"{0}" related to line number {1}',
                              new List<String> { ex.getMessage(), w.FakeId }
                              )
                          );
            }
        }
        Boolean flag = false;
        try {
            Database.SaveResult[] saveResultCaseList = Database.insert(cases, false);
            Integer i = 0;
            for (Database.SaveResult sr : saveResultCaseList) {
                i++;
                if (!sr.isSuccess()) {
                    ErrorEntity e = new ErrorEntity('1',
                                                    String.valueOf(i),
                                                    new List<String>
                                                    {sr.getErrors()[0].getMessage()});
                    errorsToFrontList.add(e);
                    flag = true;
                }
            }
            if (flag) {
                Database.rollback( sp );
            }
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        if (checkErrorsToFront(errorsToFrontList)) {
            return null;
        }
        flag = false;
        try {
            Database.SaveResult[] saveResultWorkOrderList = Database.insert(workOrders, false);
            Integer i = 0;
            for (Database.SaveResult sr : saveResultWorkOrderList) {
                i++;
                if (!sr.isSuccess()) {
                    ErrorEntity e = new ErrorEntity('1',
                                                    String.valueOf(i),
                                                    new List<String>
                                                    {sr.getErrors()[0].getMessage()});
                    errorsToFrontList.add(e);
                    flag = true;
                }
            }
            if (flag) {
                Database.rollback( sp );
            }
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        if (checkErrorsToFront(errorsToFrontList)) {
            return null;
        }
        Map<Id, Id> workOrderIdMap = new Map<Id, Id>();
        for (WorkOrder w : workOrders) {
            workOrderIdMap.put(w.PropertyId__c, w.Id);
        }
        List<Id> workOrderExcelAmountIds = new List<Id>();
        for (WorkOrderImportModel.WorkOrderExcel w : workOrderExcelList) {
            workOrderExcelAmountIds.add(workOrderIdMap.get(w.NewPropertyId));
        }
        return workOrderExcelAmountIds;
    }

    private static List<Id> createWorkOrderLineItems (
        List<WorkOrderImportModel.WorkOrderLineItemExcel> workOrderLineItemExcelList,
        List<Id> dbWorkOrderIds
        ) {
        List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
        for (WorkOrderImportModel.WorkOrderLineItemExcel wOrderLineItemExcel :
             workOrderLineItemExcelList) {
            try {
                WorkOrderLineItem wOrderLineItem = new WorkOrderLineItem(
                    WorkOrderId = dbWorkOrderIds.get(Integer.valueOf(wOrderLineItemExcel.FakeId) - 1),
                    Category__c = wOrderLineItemExcel.Category,
                    SubCategory__c = wOrderLineItemExcel.SubCategory,
                    Issue__c = wOrderLineItemExcel.Issue,
                    Description = wOrderLineItemExcel.ProblemDescription,
                    Yardi_Work_Order_Number__c = Integer.valueOf(wOrderLineItemExcel.YardiWorkOrderNumber)
                    );
                workOrderLineItems.add(wOrderLineItem);
            }
            catch (Exception ex) {
                throw new AuraHandledException(
                          String.format(
                              '"{0}" related to line number {1}',
                              new List<String> { ex.getMessage(), wOrderLineItemExcel.FakeId }
                              )
                          );
            }
        }
        Boolean flag = false;
        try {
            Database.SaveResult[] saveResultList = Database.insert(workOrderLineItems, false);
            Integer i = 0;
            for (Database.SaveResult sr : saveResultList) {
                i++;
                if (!sr.isSuccess()) {
                    ErrorEntity e = new ErrorEntity('2',
                                                    String.valueOf(i),
                                                    new List<String>
                                                    {sr.getErrors()[0].getMessage()});
                    errorsToFrontList.add(e);
                    flag = true;
                }
            }
            if (flag) {
                Database.rollback( sp );
            }
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        if (checkErrorsToFront(errorsToFrontList)) {
            return null;
        }
        List<Id> workOrderLineItemIds = new List<Id>();
        for (WorkOrderLineItem w : workOrderLineItems) {
            workOrderLineItemIds.add(w.Id);
        }
        return workOrderLineItemIds;
    }

    private static List<Id> createServiceAppointments (
        List<WorkOrderImportModel.ServiceAppointmentExcel> serviceAppointmentExcelList,
        List<Id> dbWorkOrderLineItemIds
        ) {
        List<ServiceAppointment> updatedServiceAppointments = new List<ServiceAppointment>();
        Map <Id, String> workOrderLineItemIdAndFakeIdMap = new Map<Id, String>();
        Integer n = 1;
        for (Id i : dbWorkOrderLineItemIds) {
            workOrderLineItemIdAndFakeIdMap.put(i, String.valueOf(n++));
        }
        List<ServiceAppointment> serviceAppointmentsDbList = [SELECT Id, WorkOrderLineItemId__c
                                                              FROM ServiceAppointment
                                                              WHERE WorkOrderLineItemId__c
                                                              IN :dbWorkOrderLineItemIds];
        for (ServiceAppointment servAppDb : serviceAppointmentsDbList) {
            for (WorkOrderImportModel.ServiceAppointmentExcel servAppExcel :
                 serviceAppointmentExcelList) {
                if (servAppExcel.FakeId == workOrderLineItemIdAndFakeIdMap.get(servAppDb.WorkOrderLineItemId__c)) {
                    try {
                        servAppDb.SchedStartTime = parseDateTime(servAppExcel.ScheduledStartDate,
                                                                 servAppExcel.ScheduledStartTime);
                        servAppDb.SchedEndTime = parseDateTime(servAppExcel.ScheduledFinishDate,
                                                               servAppExcel.ScheduledFinishTime);
                        servAppDb.Status = servAppExcel.Status;
                        servAppDb.Vendor_ID__c = servAppExcel.VendorId;
                        servAppDb.Employee_Code__c = servAppExcel.EmployeeCode;
                    }
                    catch (Exception ex) {
                        throw new AuraHandledException(
                                  String.format(
                                      '"{0}" related to line number {1}',
                                      new List<String> { ex.getMessage(), servAppExcel.FakeId }
                                      )
                                  );
                    }
                    break;
                }
            }
            updatedServiceAppointments.add(servAppDb);
        }
        Boolean flag = false;
        try {
            Database.SaveResult[] saveResultList = Database.update(updatedServiceAppointments, false);
            Integer i = 0;
            for (Database.SaveResult sr : saveResultList) {
                i++;
                if (!sr.isSuccess()) {
                    String message;
                    if (sr.getErrors()[0].getMessage().contains('Cannot change status')) {
                        message = 'Please check the Status of Service Appointment. ' +
                                  'It\'s not appropriate';
                    } else {
                        message = sr.getErrors()[0].getMessage();
                    }
                    ErrorEntity e = new ErrorEntity('3',
                                                    String.valueOf(i),
                                                    new List<String> {message});
                    errorsToFrontList.add(e);
                    flag = true;
                }
            }
            if (flag) {
                Database.rollback( sp );
            }
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        if (checkErrorsToFront(errorsToFrontList)) {
            return null;
        }
        List<Id> serviceAppointmentIds = new List<Id>();
        for (ServiceAppointment s : updatedServiceAppointments) {
            serviceAppointmentIds.add(s.Id);
        }
        return serviceAppointmentIds;
    }

    private static Datetime parseDateTime(String myDate, String myTime) {
        String [] dateArr = myDate.split('-');
        String [] timeArr = myTime.split(':');
        return Datetime.newInstance(Integer.valueOf(dateArr[2]),
                                    Integer.valueOf(dateArr[1]),
                                    Integer.valueOf(dateArr[0]),
                                    Integer.valueOf(timeArr[0]),
                                    Integer.valueOf(timeArr[1]),
                                    Integer.valueOf(timeArr[2])
                                    );
    }

    private static void validateWorkOrderData(WorkOrderImportModel workOrderData) {
        if (workOrderData == null) {
            throw new AuraHandledException('Failed to parse import data');
        }
        String message = workOrderData.validate();
        if (message != null) {
            throw new AuraHandledException(message);
        }
    }

    private static Boolean checkErrorsToFront(list<ErrorEntity> errorsToFrontList) {
        return errorsToFrontList.size() > 0 ? true : false;
    }
}