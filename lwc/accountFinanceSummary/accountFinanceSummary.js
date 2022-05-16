import { LightningElement,wire } from 'lwc';
import getTargetDeviation from '@salesforce/apex/AccountFinance.getTargetDeviationList';


const columns = [
    { label: 'Month', fieldName: 'month' },
    { label: 'Target', fieldName: 'totalAmount', type: 'currency' },
    { label: 'Pipeline', fieldName: 'pipeLineAmount', type: 'currency' },
    { label: 'Deviation', fieldName: 'Deviation', type: 'percentage' }
];

export default class AccountFinanceSummary extends LightningElement {
searchKey = '0015j00000dIWyeAAG';
totalTarget;
totalPipeline;
totalDeviation;
values;

data = [];
columns = columns;


    @wire(getTargetDeviation, { accId: '0015j00000dIWyeAAG'})
    accountSummary({data,error}){

         if (data) {
            this.totalTarget = data.totalTarget;
             this.totalPipeline = data.totalPipeline;
             this.totalDeviation = (Math.round(data.totalDeviation * 100) / 100).toFixed(2); 
             this.data = data.dataValues;
           console.log('Data ===',data );
        } else if (error) {
            console.log(error);
        }
        
    };

 
}