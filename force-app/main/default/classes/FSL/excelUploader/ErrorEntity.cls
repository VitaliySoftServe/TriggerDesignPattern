public with sharing class ErrorEntity {
    private String tableId;
    private String rowId;
    private List<String> errors;

    public ErrorEntity(String tableId, String rowId, List<String> errors) {
        this.tableId = tableId;
        this.rowId = rowId;
        this.errors = errors;
    }

    public String getRowId() {
        return rowId;
    }
}
