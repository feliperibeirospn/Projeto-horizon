@isTest
private class AlunoTurmaHandlerTest {

    @testSetup
    static void setupData() {
        // 1. Criar Conta do Teste
        Account contaTeste = new Account();
        
        // Em vez de buscar por ID no SOQL, pega estritamente o RecordType Padrão (Default) do usuário do teste
        for (Schema.RecordTypeInfo rt : Schema.SObjectType.Account.getRecordTypeInfos()) {
            if (rt.isDefaultRecordTypeMapping()) {
                contaTeste.RecordTypeId = rt.getRecordTypeId();
                break;
            }
        }

        // Trata Person Account vs Standard Account
        Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
        if (accountFields.containsKey('FirstName')) {
            contaTeste.put('FirstName', 'Aluno');
            contaTeste.put('LastName', 'Teste Unitario');
        } else {
            contaTeste.Name = 'Aluno Teste Unitario';
        }

        insert contaTeste;

        // 2. Criar Curso preenchendo o campo obrigatório Departamento__c
        Curso__c curso = new Curso__c();
        Schema.DescribeFieldResult deptDescribe = Curso__c.Departamento__c.getDescribe();
        
        if (deptDescribe.getType() == Schema.DisplayType.REFERENCE) {
            String parentObjectName = deptDescribe.getReferenceTo()[0].getDescribe().getName();
            sObject deptoParent = Schema.getGlobalDescribe().get(parentObjectName).newSObject();
            
            Map<String, Schema.SObjectField> parentFields = deptoParent.getSObjectType().getDescribe().fields.getMap();
            if (parentFields.containsKey('Name')) {
                deptoParent.put('Name', 'Departamento Teste');
            }
            insert deptoParent;
            curso.Departamento__c = deptoParent.Id;
        } else {
            curso.Departamento__c = 'Tecnologia';
        }

        Schema.DescribeFieldResult nameDescribe = Curso__c.Name.getDescribe();
        if (nameDescribe.isCreateable() && !nameDescribe.isAutoNumber()) {
            curso.Name = 'Curso Teste Apex';
        }
        insert curso;

        // 3. Criar Turma com capacidade para 2 alunos
        Turma__c turma = new Turma__c(
            Curso__c = curso.Id,
            Capacidade_Maxima__c = 2,
            Status_Turma__c = 'Aberta'
        );
        insert turma;
    }

    @isTest
    static void testMatriculaSucessoEStatusLotado() {
        Turma__c turma = [SELECT Id FROM Turma__c LIMIT 1];
        Account conta = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        // Insere 2 alunos (atingindo o limite de 2)
        List<AlunoTurma__c> alunos = new List<AlunoTurma__c>{
            new AlunoTurma__c(Turma__c = turma.Id, Account__c = conta.Id),
            new AlunoTurma__c(Turma__c = turma.Id, Account__c = conta.Id)
        };
        insert alunos;
        Test.stopTest();

        // Valida se a turma mudou o Status para "Lotada"
        Turma__c turmaAtualizada = [SELECT Id, Status_Turma__c FROM Turma__c WHERE Id = :turma.Id];
        System.assertEquals('Lotada', turmaAtualizada.Status_Turma__c, 'O status da turma deveria ter mudado para Lotada.');
    }

    @isTest
    static void testBloqueioCapacidadeExcedida() {
        Turma__c turma = [SELECT Id FROM Turma__c LIMIT 1];
        Account conta = [SELECT Id FROM Account LIMIT 1];

        // Preenche o limite de 2 vagas
        insert new List<AlunoTurma__c>{
            new AlunoTurma__c(Turma__c = turma.Id, Account__c = conta.Id),
            new AlunoTurma__c(Turma__c = turma.Id, Account__c = conta.Id)
        };

        Test.startTest();
        // Tenta matricular o 3º aluno na mesma turma (deve falhar via addError)
        AlunoTurma__c alunoExcedente = new AlunoTurma__c(Turma__c = turma.Id, Account__c = conta.Id);
        Database.SaveResult result = Database.insert(alunoExcedente, false);
        Test.stopTest();

        // Validações
        System.assert(!result.isSuccess(), 'A inserção do aluno excedente deveria ter falhado.');
        System.assert(result.getErrors()[0].getMessage().contains('capacidade máxima'), 'A mensagem de erro esperada não foi disparada.');
    }
}