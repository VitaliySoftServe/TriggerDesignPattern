import { LightningElement } from 'lwc';

export default class CustomWindow extends LightningElement {

    modal=false;
    isLoading=false;

    setModalToFalse(){
        this.modal=false;
    }

    handleClick() {
        this.modal=true;
        this.isLoading=true;
        setTimeout(() => {   
            this.isLoading=false;
        }, 2000);
        
    }
}