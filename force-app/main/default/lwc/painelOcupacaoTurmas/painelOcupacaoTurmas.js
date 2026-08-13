import { LightningElement, wire } from 'lwc';
import getTurmasOcupacao from '@salesforce/apex/PainelCoordenadorController.getTurmasOcupacao';

export default class PainelOcupacaoTurmas extends LightningElement {
    turmas;
    error;

    @wire(getTurmasOcupacao)
    wiredTurmas({ error, data }) {
        if (data) {
            this.turmas = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.turmas = undefined;
        }
    }
}