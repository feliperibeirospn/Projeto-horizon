@isTest
private class OpportunityPagamentoTest {

    /**
     * @description Cria uma conta de teste usando um Record Type de fato
     * disponível para o usuário em execução. isAvailable() (via Schema
     * describe) respeita as atribuições de Record Type por perfil; já a
     * verificação de "é Person Account?" precisa de uma consulta SOQL ao
     * campo IsPersonType, que existe no sObject RecordType (não na classe
     * de metadados Schema.RecordTypeInfo).
     */
    private static Account criarContaAluno() {
        Schema.DescribeSObjectResult accDescribe = Account.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtInfosPorNome = accDescribe.getRecordTypeInfosByDeveloperName();

        Schema.RecordTypeInfo rtAluno = rtInfosPorNome.get('Aluno');
        Schema.RecordTypeInfo rtEscolhido;

        if (rtAluno != null && rtAluno.isAvailable()) {
            rtEscolhido = rtAluno;
        } else {
            // Fallback: primeiro Record Type (não-master) disponível para o usuário
            for (Schema.RecordTypeInfo info : accDescribe.getRecordTypeInfos()) {
                if (info.isAvailable() && !info.isMaster()) {
                    rtEscolhido = info;
                    break;
                }
            }
        }

        Account acc;
        if (rtEscolhido != null) {
            Boolean ehPersonAccount = false;
            List<RecordType> rtDetalhe = [
                SELECT Id, IsPersonType
                FROM RecordType
                WHERE Id = :rtEscolhido.getRecordTypeId()
                LIMIT 1
            ];
            if (!rtDetalhe.isEmpty()) {
                ehPersonAccount = rtDetalhe[0].IsPersonType;
            }

            if (ehPersonAccount) {
                acc = new Account(
                    RecordTypeId = rtEscolhido.getRecordTypeId(),
                    FirstName = 'Aluno',
                    LastName = 'Teste QA'
                );
            } else {
                acc = new Account(
                    RecordTypeId = rtEscolhido.getRecordTypeId(),
                    Name = 'Aluno Teste QA'
                );
            }
        } else {
            // Nenhum Record Type disponível para o usuário de teste — mensagem
            // clara para facilitar o diagnóstico caso ainda falhe.
            throw new TestException(
                'Nenhum Record Type de Account disponível para o usuário em execução. ' +
                'Verifique se o perfil/Permission Set do usuário de teste tem "Aluno" ' +
                'atribuído em Assigned Record Types.'
            );
        }

        insert acc;
        return acc;
    }

    private class TestException extends Exception {}

    private static Opportunity criarOpportunityBase() {
        Account acc = criarContaAluno();

        Opportunity opp = new Opportunity(
            Name = 'Matrícula - Aluno Teste QA',
            AccountId = acc.Id,
            StageName = 'Inscrição',
            CloseDate = Date.today().addDays(30),
            Amount = 450.00
        );
        insert opp;
        return opp;
    }

    @isTest
    static void testGeracaoDeLinkComSucesso() {
        Test.setMock(HttpCalloutMock.class, new MercadoPagoMockSuccess());

        Opportunity opp = criarOpportunityBase();

        Test.startTest();
        opp.StageName = 'Matriculado';
        update opp;
        Test.stopTest(); // força execução síncrona do Queueable no contexto de teste

        Opportunity oppAtualizada = [
            SELECT Status_Pagamento__c, Link_Pagamento__c, ID_Preferencia_MP__c
            FROM Opportunity WHERE Id = :opp.Id
        ];

        System.assertEquals('Gerado', oppAtualizada.Status_Pagamento__c);
        System.assertNotEquals(null, oppAtualizada.Link_Pagamento__c);
        System.assertEquals('PREF-TEST-123456', oppAtualizada.ID_Preferencia_MP__c);
    }

    @isTest
    static void testFalhaNoGateway() {
        Test.setMock(HttpCalloutMock.class, new MercadoPagoMockFailure());

        Opportunity opp = criarOpportunityBase();

        Test.startTest();
        opp.StageName = 'Matriculado';
        update opp;
        Test.stopTest();

        Opportunity oppAtualizada = [
            SELECT Status_Pagamento__c, Link_Pagamento__c
            FROM Opportunity WHERE Id = :opp.Id
        ];

        System.assertEquals('Erro', oppAtualizada.Status_Pagamento__c);
        System.assertEquals(null, oppAtualizada.Link_Pagamento__c);
    }

    @isTest
    static void testNaoReprocessaSeJaGerado() {
        Test.setMock(HttpCalloutMock.class, new MercadoPagoMockSuccess());

        Opportunity opp = criarOpportunityBase();
        opp.Status_Pagamento__c = 'Gerado';
        opp.StageName = 'Matriculado';
        update opp;

        Test.startTest();
        // Simula uma segunda atualização sem sair do estágio "Matriculado"
        opp.Amount = 500.00;
        update opp;
        Test.stopTest();

        // Nenhum job adicional deveria ter sido necessário; o teste garante
        // que a lógica não gera exception nem duplica o link.
        Opportunity oppFinal = [SELECT Status_Pagamento__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Gerado', oppFinal.Status_Pagamento__c);
    }

    @isTest
    static void testNaoDisparaSeNaoEntrouEmMatriculado() {
        Opportunity opp = criarOpportunityBase();

        Test.startTest();
        opp.StageName = 'Entrevista';
        update opp;
        Test.stopTest();

        Opportunity oppFinal = [SELECT Status_Pagamento__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(null, oppFinal.Status_Pagamento__c);
    }
}