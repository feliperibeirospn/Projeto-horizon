/**
 * @description Processa a geração do link de pagamento de forma assíncrona,
 * pois callouts HTTP não são permitidos de forma síncrona dentro de triggers.
 */
public class GerarLinkPagamentoQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> opportunityIds;

    public GerarLinkPagamentoQueueable(Set<Id> opportunityIds) {
        this.opportunityIds = opportunityIds;
    }

    public void execute(QueueableContext context) {
        List<Opportunity> opps = [
            SELECT Id, Name, Amount, Status_Pagamento__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];

        List<Opportunity> paraAtualizar = new List<Opportunity>();

        for (Opportunity opp : opps) {
            PaymentGatewayService.PaymentResult resultado =
                PaymentGatewayService.criarPreferenciaPagamento(opp);

            Opportunity oppAtualizada = new Opportunity(Id = opp.Id);

            if (resultado.success) {
                oppAtualizada.Link_Pagamento__c = resultado.checkoutUrl;
                oppAtualizada.ID_Preferencia_MP__c = resultado.preferenceId;
                oppAtualizada.Status_Pagamento__c = 'Gerado';
                oppAtualizada.Pagamento_Gerado_Em__c = System.now();
            } else {
                oppAtualizada.Status_Pagamento__c = 'Erro';
                // Em produção, considere logar resultado.errorMessage numa
                // Custom Object de Log de Integração para auditoria.
            }

            paraAtualizar.add(oppAtualizada);
        }

        if (!paraAtualizar.isEmpty()) {
            update paraAtualizar;
        }
    }
}