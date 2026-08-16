/**
 * @description Mock de callout simulando resposta de erro do Mercado Pago,
 * usado para validar o tratamento de falha no PaymentGatewayService.
 */
@isTest
global class MercadoPagoMockFailure implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(401);
        res.setBody('{"message":"invalid access token"}');
        return res;
    }
}