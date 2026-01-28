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





