/**
 * @description Mock de callout simulando resposta de sucesso do Mercado Pago,
 * usado nos testes unitários (nenhum callout real é feito em @isTest).
 */
@isTest
global class MercadoPagoMockSuccess implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(201);

        Map<String, Object> body = new Map<String, Object>{
            'id' => 'PREF-TEST-123456',
            'sandbox_init_point' => 'https://sandbox.mercadopago.com.br/checkout/TEST-123456',
            'init_point' => 'https://www.mercadopago.com.br/checkout/TEST-123456'
        };
        res.setBody(JSON.serialize(body));
        return res;
    }
}