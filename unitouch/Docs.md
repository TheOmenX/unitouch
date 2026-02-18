##DATAGET

DATAGET _:
    - WAITER.txt: get list of waiters
        <id> <name> <code>\n
    - REMARKS.txt: List of all items that are remarks
        <rang> <id> <name>\n
    - TYPES.txt: all catagories in hand held
        <id> <name>\n
    - ART.txt: all items, if items are no remark
        <id> <name> <TYPES:id> <price> F 0 <rang> ...\n
    - TBLCELL.txt
        <BTNfrmCnt: int> <BTNcllCnt: int> <BTNlabel: string> <BTNx: int> <BTNy: int> <BTNw: int> <BTNh: int> <BTNr: int> <BTNaccNum: int>
    - TBLCOLORS.txt
        <buttoncolorsID: int> <BTNStatus: int> <BTNFill: int> <BTNText: int>\n
    

## ACCSPLIT
ACCSPLIT 1 <old_table> 1 <new_table>
    (After that list of items moved : followed by //END)
<user> <PLU> <name> <removed(empty)> <amount> <rang> F <price> * <amount> <place> 0

##GETNRP


##SETNRP
SETNRP <? 1> <table> <amount>
    Set number of persons
    
##ACCPAY
ACCPAY <? 1> table
    <payment method id> <payment method name> <_>
    97 Interpay Plus 3 0 1 Tijn 0 RepBillSmall 0 1 MAESTRO 679058******5042 16402188 <some uid>

##ACCPUT
ACCPUT

    


##Viva Payments
###Referal
vivapayclient://pay/v1?callback=unitouch&merchantKey=1570006a-b5c8-ed11-b597-0022489e30c9&appId=com.tijngiesberts.unitouch&action=sale&amount=1&tipAmount=1&clientTransactionId=210

###Callback
unitouch://result?transactionId=03e62a3b-a05d-4941-a194-f12722b7a4ab&transactionEventId=0&bankId=NET_MASTER&appId=A0000000043060&tipAmount=1&transactionDate=2026-01-30T20:12:08.976+0100&amount=2&cardType=Maestro&transactionTypeId=5&verificationMethod=Contactless&accountNumber=************5023&tid=16569864&authorisationCode=021A31&shortOrderCode=6030207782&action=sale&clientTransactionId=210&status=success&message=Transaction%20successful&merchantReference=210&referenceNumber=631366&rrn=603019631366&orderCode=6030207782569864







##Error Codes

200 Ok
201 ready

400 Syntax Error
401 Account Locked
402 Destination Account Locked
426 
