/**
 * @description Serviço responsável por criar uma preferência de pagamento
 * no Mercado Pago (sandbox) para a matrícula do aluno, a partir da Opportunity.
 * Endpoint utilizado: POST https://api.mercadopago.com/checkout/preferences
 */
public with sharing class PaymentGatewayService {

    private static final String MP_ENDPOINT = 'https://api.mercadopago.com/checkout/preferences';

    /**
     * @description Wrapper de retorno para o chamador (trigger/handler).
     */
    public class PaymentResult {
        public Boolean success;
        public String preferenceId;
        public String checkoutUrl;
        public String errorMessage;
    }

    /**
     * @description Cria uma preferência de pagamento no Mercado Pago
     * para a Opportunity informada.
     * @param opp Opportunity já com Amount e Name preenchidos
     */
    public static PaymentResult criarPreferenciaPagamento(Opportunity opp) {
        PaymentResult resultado = new PaymentResult();

        String token = obterAccessToken();
        if (String.isBlank(token)) {
            resultado.success = false;
            resultado.errorMessage = 'Access Token do gateway não configurado em Custom Metadata.';
            return resultado;
        }

        Decimal valor = (opp.Amount != null && opp.Amount > 0) ? opp.Amount : 1.00; // fallback p/ teste

        Map<String, Object> item = new Map<String, Object>{
            'title'       => 'Matrícula - ' + opp.Name,
            'quantity'    => 1,
            'currency_id' => 'BRL',
            'unit_price'  => valor
        };

        Map<String, Object> body = new Map<String, Object>{
            'items'              => new List<Object>{ item },
            'external_reference' => opp.Id,
            'back_urls'          => new Map<String, Object>{
                'success' => 'https://www.mercadopago.com.br',
                'failure' => 'https://www.mercadopago.com.br',
                'pending' => 'https://www.mercadopago.com.br'
            }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(MP_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setBody(JSON.serialize(body));
        req.setTimeout(15000);

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> respBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                resultado.success = true;
                resultado.preferenceId = (String) respBody.get('id');
                // Em sandbox, use sandbox_init_point; em produção, init_point
                resultado.checkoutUrl = (String) respBody.get('sandbox_init_point');
                if (String.isBlank(resultado.checkoutUrl)) {
                    resultado.checkoutUrl = (String) respBody.get('init_point');
                }
            } else {
                resultado.success = false;
                resultado.errorMessage = 'HTTP ' + res.getStatusCode() + ': ' + res.getBody();
            }
        } catch (Exception e) {
            resultado.success = false;
            resultado.errorMessage = 'Erro no callout: ' + e.getMessage();
        }

        return resultado;
    }

    private static String obterAccessToken() {
        Config_Gateway_Pagamento__mdt config = Config_Gateway_Pagamento__mdt.getInstance('Sandbox');
        return config != null ? config.Access_Token__c : null;
    }
}