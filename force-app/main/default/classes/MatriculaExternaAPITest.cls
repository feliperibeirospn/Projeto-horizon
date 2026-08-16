@isTest
private class MatriculaExternaAPITest {

    @isTest
    static void testCriarCandidatoSucesso() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/MatriculaExterna/';
        req.httpMethod = 'POST';
        
        String jsonPayload = '{' +
            '"primeiroNome": "Lucas",' +
            '"ultimoNome": "Silva",' +
            '"email": "lucas.silva@teste.com",' +
            '"telefone": "84999998888",' +
            '"cpf": "11122233344"' +
        '}';

        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        MatriculaExternaAPI.ApiResponse response = MatriculaExternaAPI.criarCandidato();
        Test.stopTest();

        System.assertEquals(201, res.statusCode, 'Status code deve ser 201 Created.');
        System.assertEquals(true, response.success, 'Sucesso deve ser true.');
        System.assertNotEquals(null, response.leadId, 'LeadId deve ser retornado.');

        Lead leadCriado = [SELECT Id, LastName, CPF__c FROM Lead WHERE Id = :response.leadId];
        System.assertEquals('Silva', leadCriado.LastName);
        System.assertEquals('11122233344', leadCriado.CPF__c);
    }

    @isTest
    static void testCriarCandidatoValidacaoErro() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/MatriculaExterna/';
        req.httpMethod = 'POST';
        
        String jsonInvalido = '{"primeiroNome": "Teste", "cpf": "123"}';

        req.requestBody = Blob.valueOf(jsonInvalido);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        MatriculaExternaAPI.ApiResponse response = MatriculaExternaAPI.criarCandidato();
        Test.stopTest();

        System.assertEquals(400, res.statusCode, 'Status code deve ser 400 Bad Request.');
        System.assertEquals(false, response.success);
    }

    @isTest
    static void testPayloadVazio() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/MatriculaExterna/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        MatriculaExternaAPI.ApiResponse response = MatriculaExternaAPI.criarCandidato();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        System.assertEquals(false, response.success);
    }
}