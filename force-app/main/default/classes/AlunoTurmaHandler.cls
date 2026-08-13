public with sharing class AlunoTurmaHandler {

    /**
     * Valida capacidade da Turma antes de matricular o Aluno.
     */
    public void beforeInsert(List<AlunoTurma__c> newAlunos) {
        Set<Id> turmaIds = new Set<Id>();

        for (AlunoTurma__c aluno : newAlunos) {
            if (aluno.Turma__c != null) {
                turmaIds.add(aluno.Turma__c);
            }
        }

        if (turmaIds.isEmpty()) return;

        // Mapeia turmas e busca sub-query dos alunos já associados
        Map<Id, Turma__c> turmasMap = new Map<Id, Turma__c>([
            SELECT Id, Name, Capacidade_Maxima__c, 
                   (SELECT Id FROM AlunosTurma__r) 
            FROM Turma__c 
            WHERE Id IN :turmaIds
        ]);

        Map<Id, Integer> novosAlunosPorTurma = new Map<Id, Integer>();

        for (AlunoTurma__c aluno : newAlunos) {
            Turma__c turma = turmasMap.get(aluno.Turma__c);
            
            if (turma != null && turma.Capacidade_Maxima__c != null) {
                Integer matriculadosAtuais = (turma.AlunosTurma__r != null) ? turma.AlunosTurma__r.size() : 0;
                Integer novosNesteLote = novosAlunosPorTurma.containsKey(turma.Id) 
                    ? novosAlunosPorTurma.get(turma.Id) : 0;

                if ((matriculadosAtuais + novosNesteLote) >= turma.Capacidade_Maxima__c) {
                    aluno.addError('A turma ' + turma.Name + ' já atingiu a capacidade máxima de ' + 
                                   turma.Capacidade_Maxima__c.intValue() + ' alunos.');
                } else {
                    novosAlunosPorTurma.put(turma.Id, novosNesteLote + 1);
                }
            }
        }
    }

    /**
     * Atualiza o Status da Turma para "Lotada" após a inserção.
     */
    public void afterInsert(List<AlunoTurma__c> newAlunos) {
        Set<Id> turmaIds = new Set<Id>();

        for (AlunoTurma__c aluno : newAlunos) {
            if (aluno.Turma__c != null) {
                turmaIds.add(aluno.Turma__c);
            }
        }

        if (turmaIds.isEmpty()) return;

        List<Turma__c> turmasParaAtualizar = new List<Turma__c>();

        for (Turma__c turma : [
            SELECT Id, Capacidade_Maxima__c, Status_Turma__c, 
                   (SELECT Id FROM AlunosTurma__r) 
            FROM Turma__c 
            WHERE Id IN :turmaIds AND Status_Turma__c != 'Lotada'
        ]) {
            if (turma.Capacidade_Maxima__c != null && 
                turma.AlunosTurma__r.size() >= turma.Capacidade_Maxima__c) {
                
                turma.Status_Turma__c = 'Lotada';
                turmasParaAtualizar.add(turma);
            }
        }

        if (!turmasParaAtualizar.isEmpty()) {
            update turmasParaAtualizar;
        }
    }
}