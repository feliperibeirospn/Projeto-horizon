public with sharing class PainelCoordenadorController {

    @AuraEnabled(cacheable=true)
    public static List<TurmaDTO> getTurmasOcupacao() {
        List<TurmaDTO> resultado = new List<TurmaDTO>();

        // Busca turmas e traz a contagem de alunos vinculados
        for (Turma__c turma : [
            SELECT Id, Name, Capacidade_Maxima__c, Status_Turma__c,
                   (SELECT Id FROM AlunosTurma__r)
            FROM Turma__c
            LIMIT 50
        ]) {
            Integer matriculados = turma.AlunosTurma__r != null ? turma.AlunosTurma__r.size() : 0;
            resultado.add(new TurmaDTO(turma, matriculados));
        }

        return resultado;
    }

    // Classe Wrapper (DTO) para facilitar a renderização no LWC
    public class TurmaDTO {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String nome { get; set; }
        @AuraEnabled public Integer capacidade { get; set; }
        @AuraEnabled public Integer matriculados { get; set; }
        @AuraEnabled public Integer percentual { get; set; }
        @AuraEnabled public String status { get; set; }

        public TurmaDTO(Turma__c turma, Integer matriculados) {
            this.id = turma.Id;
            this.nome = turma.Name;
            this.capacidade = turma.Capacidade_Maxima__c != null ? turma.Capacidade_Maxima__c.intValue() : 0;
            this.matriculados = matriculados;
            this.status = turma.Status_Turma__c;

            if (this.capacidade > 0) {
                this.percentual = Math.min(100, (Integer)Math.round(((double)matriculados / this.capacidade) * 100));
            } else {
                this.percentual = 0;
            }
        }
    }
}