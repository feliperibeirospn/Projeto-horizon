@RestResource(urlMapping='/MatriculaExterna/*')
global with sharing class MatriculaExternaAPI {

    global class CandidatoRequest {
        public String primeiroNome;
        public String ultimoNome;
        public String email;
        public String telefone;
        public String cpf;
        public String cursoInteresse;
        public String campus;
    }

    global class ApiResponse {
        public Boolean success;
        public String message;
        public String leadId;
        public List<String> errors;

        public ApiResponse(Boolean success, String message, String leadId, List<String> errors) {
            this.success = success;
            this.message = message;
            this.leadId = leadId;
            this.errors = errors;
        }
    }

    @HttpPost
    global static ApiResponse criarCandidato() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        List<String> validationErrors = new List<String>();

        try {
            String requestBody = req.requestBody != null ? req.requestBody.toString() : '';
            if (String.isBlank(requestBody)) {
                res.statusCode = 400;
                return new ApiResponse(false, 'Payload vazio.', null, new List<String>{'O corpo da requisição JSON é obrigatório.'});
            }

            CandidatoRequest dados = (CandidatoRequest) JSON.deserialize(requestBody, CandidatoRequest.class);

            if (String.isBlank(dados.ultimoNome)) {
                validationErrors.add('O campo "ultimoNome" é obrigatório para criação de Lead.');
            }
            if (String.isBlank(dados.cpf)) {
                validationErrors.add('O campo "cpf" é obrigatório.');
            }

            if (!validationErrors.isEmpty()) {
                res.statusCode = 400;
                return new ApiResponse(false, 'Falha na validação dos dados recebidos.', null, validationErrors);
            }

            Lead novoLead = new Lead();
            novoLead.FirstName = dados.primeiroNome;
            novoLead.LastName = dados.ultimoNome;
            // Em orgs com Person Account, se o Lead for individual, preencher Company com o próprio nome ou valor neutro:
            novoLead.Company = dados.primeiroNome != null ? (dados.primeiroNome + ' ' + dados.ultimoNome) : dados.ultimoNome;
            novoLead.Email = dados.email;
            novoLead.Phone = dados.telefone;
            novoLead.LeadSource = 'Sistema Externo / Parceiro';
            novoLead.CPF__c = dados.cpf;

            insert novoLead;

            res.statusCode = 201;
            return new ApiResponse(true, 'Candidato/Lead criado com sucesso!', novoLead.Id, null);

        } catch (Exception ex) {
            res.statusCode = 500;
            return new ApiResponse(false, 'Erro interno ao processar requisição.', null, new List<String>{ex.getMessage()});
        }
    }
}