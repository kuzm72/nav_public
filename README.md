### BC365 / Price Calculation 3rd Party Software Integration

*Use Case:*

The user creates sales order in BC365 using standard functionality. 
On the header level, location and sell-to customer information is specified.
On lines level, the user add all required item lines with corresponding quantities. Line amounts left as they are.
The user releases the order.
The user presses Retrieve Prices action.
BC365 sends sales order data as web request to external web service endpoint (POST mether, use toool like [Mockoon](https://mockoon.com/) to create mock-up interface);
Use JSON format for communication. SH fields to be sent: order number, location code, customer code; SL fields to be sent (as JSOM sub-array):line no, item no, quantity;
External system sends back order data to BC365 as web response with calculated sales prices.  
Use JSON format for communication. Fields to be pushed to BC365: Order header: order number; Item lines: line number, item number, calculated line amount;

The system should update the order with line amounts received from web service;