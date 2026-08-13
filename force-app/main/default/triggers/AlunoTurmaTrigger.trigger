trigger AlunoTurmaTrigger on AlunoTurma__c (before insert, after insert) {
    AlunoTurmaHandler handler = new AlunoTurmaHandler();

    if (Trigger.isBefore && Trigger.isInsert) {
        handler.beforeInsert(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert(Trigger.new);
    }
}