import { LightningElement, api} from 'lwc';
import deleteAll from '@salesforce/apex/DeleteHistories.deleteAll';

export default class DeleteHistories extends LightningElement {
    
    @api recordId;
    clickedButtonLabel;

    handleClick() {
        if (confirm('Warning! Are you sure you want to delete all the related History records?')){
            deleteAll( {testId:this.recordId} )
            .then( result => {
                this.clickedButtonLabel=result;
                alert(result); 
            })
            .catch(error => {
                alert('An error occured! Code: ' + error.errorCode + ' ' + ', Message: ' + error.body.message);
            });; 
        } 
    }
}