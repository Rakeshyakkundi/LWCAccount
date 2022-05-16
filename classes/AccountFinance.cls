public class AccountFinance {
    public static Map<Integer,String> monthName = new Map<Integer,String>{
        1 => 'Jan',
            2 => 'Feb',
            3 => 'Mar',
            4 => 'April',
            5 => 'May',
            6 => 'June',
            7 => 'July',
            8 => 'Aug',
            9 => 'Sept',
            10 => 'Oct',
            11 => 'Nov',
            12=> 'Dec'
            };
    //Target
    public static Map<Integer, Decimal>  getTargetList(Id accId){
        List<Account_Target__c > accountTarget = [SELECT Date__c, Amount__c  FROM Account_Target__c  WHERE Date__c=THIS_FISCAL_YEAR  AND Account__c=:AccId ORDER BY Date__c ASC];
        //mapTarget has Month,Target Value
        Map<Integer, Decimal> mapTarget = new Map<Integer, Decimal>();        
        Decimal valuesTarget;
        // try block will check is the month in Map if yes the total value will be added
        // catch block if month not present it will create key and value 
        for(Integer j=0;j<accountTarget.size();j++){
            try{
                valuesTarget =mapTarget.get(accountTarget[j].Date__c.month());
                mapTarget.put(accountTarget[j].Date__c.month(),valuesTarget+accountTarget[j].Amount__c);
            }catch(Exception e){
                mapTarget.put(accountTarget[j].Date__c.month(),accountTarget[j].Amount__c);
            }
        }  
        return mapTarget;
        
    }
    
    // Pipeline
    public static Map<Integer, Decimal> getPielineList(Id accId){
        List<OpportunityExtension__c> oppPipeline=[SELECT Id, Amount__c, Opportunity__c, Date__c, Name ,Opportunity__r.stageName  FROM OpportunityExtension__c   WHERE Date__c=THIS_FISCAL_YEAR AND Opportunity__r.StageName !='Won' AND Opportunity__r.StageName !='Lost'  AND Opportunity__r.AccountId =:AccId];
        //mapTarget has Month,Opportunity amount
        Map<Integer, Decimal> mapPipeLine = new Map<Integer, Decimal>();
        Decimal valuesAmount;
        // try block will check is the month in Map if yes the total value will be added
        // catch block if month not present it will create key and value 
        for(Integer j=0;j<oppPipeline.size();j++){
            try{
                valuesAmount = mapPipeLine.get(oppPipeline[j].Date__c.month());//oppPipeline[j].Date__c.month() -> returns month 
                mapPipeLine.put(oppPipeline[j].Date__c.month(),valuesAmount+oppPipeline[j].Amount__c);
            }catch(Exception e){
                mapPipeLine.put(oppPipeline[j].Date__c.month(),oppPipeline[j].Amount__c);
            }
        }
        return mapPipeLine;
    }
    
    //Target Deviation
     @AuraEnabled(cacheable=true)
    public static Wrapper getTargetDeviationList(Id accId){
        Map<Integer,Decimal> TargetMap = getTargetList(accId); // Has month and Target
        Map<Integer,Decimal> PipeLineMap = getPielineList(accId); // Has month and sum of opportunity amount
        
        List<Decimal> ListForTarget = new List<Decimal>();
        List<Decimal> ListForPipeline = new List<Decimal>();
        List<Decimal> ListForTotalDeviation = new List<Decimal>();
        List<wrapTarget> wraptarget = new List<wrapTarget>();
        List<wrapPipeline> wrapPipeline = new List<wrapPipeline>();
        List<wrapDeviation> wrapDeviation = new List<wrapDeviation>();
        
        List<wrapData> dataValues = new List<wrapData>();
        
        Decimal totalTarget =0;
        Decimal totalPipeline =0;
        Decimal totalDeviation = 0;
        // Get users fiscal year start month to display data accordingly
        Integer FiscalYearStartMonth = [select FiscalYearStartMonth from Organization where id=:Userinfo.getOrganizationId()].FiscalYearStartMonth;        
        // itterate 12 for 12 months start with fiscal year
        for(Integer i=0;i<12;i++){
            // Append list with target which start of fiscal year month ex:april then 4 initial of ListForTarget is taken from map of target
            // If null append as 0.00 in List of Target
            if(TargetMap.get(FiscalYearStartMonth)==null){
                ListForTarget.add(0.00);
            }else{
                ListForTarget.add(TargetMap.get(FiscalYearStartMonth));
            }
            // Append list of pipeline which start from fiscal year month . If null the append as 0.00
            if(PipeLineMap.get(FiscalYearStartMonth)==null){
                ListForPipeline.add(0.00);
            }else{
                ListForPipeline.add(PipeLineMap.get(FiscalYearStartMonth));
            }
            //Calculate Target Deviation as List of Target and pipeline is appended
            //if the values is not divided by 0 the try block will run . if values is divided by 0 the catch will run 
            try{
                ListForTotalDeviation.add(Math.rint(((ListForPipeline[i]-ListForTarget[i])/ListForTarget[i] )*100));
            } 
            catch(Exception e){
                ListForTotalDeviation.add(Math.rint(((ListForPipeline[i]-ListForTarget[i])/1)*100));
            }
            System.debug('Target of '+FiscalYearStartMonth+' is : '+ListForTarget[i]+'======= Pipeline '+FiscalYearStartMonth+' is : '+ListForPipeline[i]+'======Traget Deviation:'+ListForTotalDeviation[i]);
            
            wrapTarget target = new wrapTarget();
            wrapPipeline pipeline = new wrapPipeline();
            wrapDeviation deviation = new wrapDeviation();
            wrapData data = new wrapData();
            data.month = monthName.get(FiscalYearStartMonth);
            data.totalAmount = ListForTarget[i];
            data.pipeLineAmount = ListForPipeline[i];
            data.Deviation = ListForTotalDeviation[i];
            
            dataValues.add(data);
            
            target.month = FiscalYearStartMonth;
            target.Amount = ListForTarget[i];
            wraptarget.add(target);
            
            
            pipeline.month = FiscalYearStartMonth;
            pipeline.Amount = ListForPipeline[i];
            wrapPipeline.add(pipeline);
            
            
            deviation.month = FiscalYearStartMonth;
            deviation.Amount = ListForTotalDeviation[i];
            wrapDeviation.add(deviation);
            
            
            //Increase the FiscalYearStartMonth to get value from map of Target and pipeline
            //if FiscalYearStartMonth is 12 then reinitiate with 1 to start from Jan
           
            if(FiscalYearStartMonth==12){
                FiscalYearStartMonth=0;
            }
            FiscalYearStartMonth +=1;
            totalTarget = totalTarget + ListForTarget[i];
            totalPipeline = totalPipeline + ListForPipeline[i];   
            totalDeviation = ((totalTarget - totalPipeline)*100)/totalTarget;
            
        }
        
        
        Wrapper wrap = new Wrapper(totalTarget,totalPipeline,totalDeviation,dataValues);
        
        System.debug(' Final Output '+ JSON.serialize(wrap));
        return wrap;
        
    }
    
    public class wrapper {
        @AuraEnabled
        public decimal totalTarget {get; set;}
        @AuraEnabled
        public decimal totalPipeline {get; set;}
        @AuraEnabled
        public decimal totalDeviation{get; set;}
        @AuraEnabled
        public List<wrapData> dataValues {get; set;}
        
        
        
        //This is the contructor method. When we create a new wrapAccount object we pass a Account that is set to the acc property. We also set the selected value to false
        public wrapper(decimal totalTarget, decimal totalPipeline,decimal totalDeviation,List<wrapData> dataValues) {
            this.totalTarget = totalTarget;
            this.totalPipeline = totalPipeline;
            this.totalDeviation = totalDeviation;
            this.dataValues = dataValues;
        }
    }
    public class wrapTarget {
        @AuraEnabled
        public integer month {get; set;}
        @AuraEnabled
        public decimal Amount {get; set;}
    }
    
    public class wrapPipeline {
        @AuraEnabled
        public integer month {get; set;}
        @AuraEnabled
        public decimal Amount {get; set;}
    }
    
    public class wrapDeviation {
        @AuraEnabled
        public integer month {get; set;}
        @AuraEnabled
        public decimal Amount {get; set;}
    }
    
    public class wrapData {
        @AuraEnabled
        public String month {get; set;}
        @AuraEnabled
        public Decimal totalAmount {get; set;}
        @AuraEnabled
        public Decimal pipeLineAmount {get; set;}
        @AuraEnabled
        public decimal Deviation {get; set;}
    }
}