/**
 * @description Handler bulkificado: identifica Oportunidades que acabaram
 * de entrar em "Matriculado" e enfileira a geração assíncrona do link
 * de pagamento, evitando reprocessamento e respeitando limites de callout.
 */
public class OpportunityPagamentoHandler {

    private static final String ESTAGIO_MATRICULADO = 'Matriculado';

    public static void processarMudancaDeEstagio(
        List<Opportunity> novasOpps,
        Map<Id, Opportunity> mapaAntigo
    ) {
        Set<Id> idsParaProcessar = new Set<Id>();

        for (Opportunity opp : novasOpps) {
            Opportunity oppAntiga = mapaAntigo.get(opp.Id);

            Boolean entrouEmMatriculado =
                opp.StageName == ESTAGIO_MATRICULADO &&
                oppAntiga.StageName != ESTAGIO_MATRICULADO;

            Boolean aindaNaoGerouPagamento =
                opp.Status_Pagamento__c != 'Gerado';

            if (entrouEmMatriculado && aindaNaoGerouPagamento) {
                idsParaProcessar.add(opp.Id);
            }
        }

        if (!idsParaProcessar.isEmpty()) {
            // Enfileira fora da transação de trigger (assíncrono),
            // respeitando o limite de 1 Queueable por transação síncrona.
            System.enqueueJob(new GerarLinkPagamentoQueueable(idsParaProcessar));
        }
    }
}