using scp.cloud as my from '../db/schema';

    @requires: 'authenticated-user'
service IncidentService {
    //Dhanush B Gangatkar
    //  entity rules01 as SELECT a.*, b.RULE_NAME, c.DEPARTMENT_NAME
    //             	FROM my.RULE as a
    //             	inner join my.RULE_SNRO as b
    //             	on a.RULE_ID = b.RULE_ID
    //                 left join my.DEPARTMENTAL_BUDGET_MASTER as c
    //                 on a.D_VALUE = cast(c.DEPARTMENT_ID as String)
    //                 where b.IS_APPROVAL = 'y'
    //             	order by a.RULE_ID;

    entity RULE                            as
        projection on my.RULE
        as a {
            *,
            a.ruletorule_snro.RULE_NAME,
            a.ruletod_b_m.DEPARTMENT_NAME
        }
        where
                a.RULE_ID                   = ruletorule_snro.RULE_ID
            and ruletorule_snro.IS_APPROVAL = 'y' 
            order by RULE_ID;

    entity rule_approver                   as projection on my.RULE_APPROVER;
    entity Member                          as projection on my.Member;
    entity ![group]                        as projection on my.Group;
    //Akshay
    entity TAX_CODE1                       as projection on my.TAX_CODE;
    


}

service ChartService {
    //Invoice Summary Report
    //api:fetch-invoice ,Invoice Summary objpage
    entity files                           as
        select
            ATTACH_ID,
            FILE_ID,
            NAME,
            MIME_TYPE,
            FILE_LINK
        from my.FILE_STORAGE;


    entity approvers                       as
        select
            a.MEMBER_ID,
            a.APPROVED_DATE,
            m.FS_NAME,
            m.LS_NAME
        from my.APPROVAL_HISTORY as a
        join my.Member as m
            on a.MEMBER_ID = m.MEMBER_ID;

    entity item                            as projection on my.Invoice_Item;
    entity error_log                       as projection on my.SAP_ERROR_LOG;

    @cds.query.limit.reliablePaging: true
    @cds.query.limit.default       : 5
    @cds.query.limit.max           : 5
    entity fetch_invoice                   as
        select
            a.*,
            b.VENDOR_NAME,
            c.VALUE2
        from my.Invoice_Header as a
        left join my.VENDOR_MASTER as b
            on a.SUPPLIER_ID = b.VENDOR_NO
        left join my.DROPDOWN as c
            on a.DOCUMENT_TYPE = c.VALUE1;

    //api:invoice-overview, Invoice overview Chart
    entity invoice_overview                as
        select
            cast(
                count( * ) as             Decimal(15, 0)
            ) as total,
            cast(
                sum(
                    case
                        when
                            IN_STATUS = 'draft'
                        then
                            1
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as draft,
            cast(
                sum(
                    case
                        when
                            IN_STATUS = 'draft'
                        then
                            cast(
                                AMOUNT as Decimal(15, 2)
                            )
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as draft_amount,
            cast(
                sum(
                    case
                        when
                            IN_STATUS = 'inapproval'
                        then
                            1
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as inapproval,
            cast(
                sum(
                    case
                        when
                            IN_STATUS = 'inapproval'
                        then
                            cast(
                                AMOUNT as Decimal(15, 2)
                            )
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as inapproval_amount,
            cast(
                sum(
                    case
                        when
                            IN_STATUS = 'tosap'
                        then
                            1
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as tosap,
            cast(
                sum(
                    case
                        when
                            IN_STATUS = 'tosap'
                        then
                            cast(
                                AMOUNT as Decimal(15, 2)
                            )
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as tosap_amount,
            cast(
                sum(
                    case
                        when
                            IN_STATUS          = 'tosap'
                            and PAYMENT_STATUS = 'unpaid'
                        then
                            1
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as tosap_ps,
            cast(
                sum(
                    case
                        when
                            IN_STATUS          = 'tosap'
                            and PAYMENT_STATUS = 'unpaid'
                        then
                            cast(
                                AMOUNT as Decimal(15, 2)
                            )
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as tosap_amount_ps,
            cast(
                sum(
                    case
                        when
                            IN_STATUS = 'new'
                        then
                            1
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as new,
            cast(
                sum(
                    case
                        when
                            IN_STATUS = 'new'
                        then
                            cast(
                                AMOUNT as Decimal(15, 2)
                            )
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as new_amount,
            cast(
                sum(
                    case
                        when
                            IN_STATUS = 'rejected'
                        then
                            1
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as rejected,
            cast(
                sum(
                    case
                        when
                            IN_STATUS = 'rejected'
                        then
                            cast(
                                AMOUNT as Decimal(15, 2)
                            )
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as rejected_amount,
            cast(
                sum(
                    case
                        when
                            IN_STATUS          = 'tosap'
                            and PAYMENT_STATUS = 'paid'
                        then
                            1
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as paid,
            cast(
                sum(
                    case
                        when
                            IN_STATUS          = 'tosap'
                            and PAYMENT_STATUS = 'paid'
                        then
                            cast(
                                AMOUNT as Decimal(15, 2)
                            )
                        else
                            0
                    end
                ) as                      Decimal(15, 2)
            ) as paid_amount
        from my.Invoice_Header
        where
            DOCUMENT_TYPE = 'RE';


    //api:account-payable  InvoiceSum -> Total Account Payable chart

    entity account_payable                 as
        select
            INVOICE_NO,
            IN_STATUS,
            AMOUNT,
            BASELINE_DATE
        from my.Invoice_Header
        where
                IN_STATUS         != 'deleted'
            and DOCUMENT_TYPE     =  'RE'
            and MONTH(ENTRY_DATE) =  MONTH(
                CURDATE()
            );
    //-- end of Invoice Summary

    //Liability Report

    //api:liability-report Liability Report
    entity liability_report                as
        select
            A.VENDOR_NO,
            A.VENDOR_NAME,
            cast(
                COUNT(
                    B.INVOICE_NO
                ) as                                      Integer
            ) as TOTAL_NO_OF_INVOICE,
            B.INVOICE_DATE,
            B.DUE_DATE,
            B.COMPANY_CODE,
            B.AMOUNT,
            B.CURRENCY,
            cast(
                sum(
                    case
                        when
                            (
                                (
                                    DAYS_BETWEEN(
                                        cast(
                                            B.DUE_DATE as Date
                                        ), CURRENT_DATE
                                    ) >= 0
                                )
                                and B.IN_STATUS != 'TOSAP'
                            )
                        then
                            cast(
                                B.AMOUNT as               Decimal(15, 2)
                            )
                        else
                            0
                    end
                ) as                                      Decimal(15, 2)
            ) as DUE_AMOUNT,
            cast(
                sum(
                    case
                        when
                            (
                                (
                                    DAYS_BETWEEN(
                                        cast(
                                            B.DUE_DATE as Date
                                        ), CURRENT_DATE
                                    ) < 0
                                )
                                and B.IN_STATUS != 'TOSAP'
                            )
                        then
                            cast(
                                B.AMOUNT as               Decimal(15, 2)
                            )
                        else
                            0
                    end
                ) as                                      Decimal(15, 2)
            ) as OVERDUE_AMOUNT,
            cast(
                sum(
                    case
                        when
                            (
                                B.IN_STATUS          = 'TOSAP'
                                and B.PAYMENT_STATUS = 'UNPAID'
                            )
                        then
                            cast(
                                B.AMOUNT as               Decimal(15, 2)
                            )
                        else
                            0
                    end
                ) as                                      Decimal(15, 2)
            ) as PROCESSED_AMOUNT,
            cast(
                sum(
                    case
                        when
                            (
                                B.IN_STATUS          = 'TOSAP'
                                and B.PAYMENT_STATUS = 'PAID'
                            )
                        then
                            B.AMOUNT
                        else
                            0
                    end
                ) as                                      Decimal(15, 2)
            ) as PAID_AMOUNT,
            cast(
                sum(
                    case
                        when
                            (
                                (
                                    DAYS_BETWEEN(
                                        cast(
                                            B.DUE_DATE as Date
                                        ), CURRENT_DATE
                                    ) >= 0
                                )
                                and B.IN_STATUS != 'TOSAP'
                            )
                        then
                            1
                        else
                            0
                    end
                ) as                                      Decimal(15, 2)
            ) as DUE_INVOICE,
            cast(
                sum(
                    case
                        when
                            (
                                (
                                    DAYS_BETWEEN(
                                        cast(
                                            B.DUE_DATE as Date
                                        ), CURRENT_DATE
                                    ) < 0
                                )
                                and B.IN_STATUS != 'TOSAP'
                            )
                        then
                            1
                        else
                            0
                    end
                ) as                                      Decimal(15, 2)
            ) as OVERDUE_INVOICE,
            cast(
                sum(
                    case
                        when
                            (
                                B.IN_STATUS          = 'TOSAP'
                                and B.PAYMENT_STATUS = 'UNPAID'
                            )
                        then
                            1
                        else
                            0
                    end
                ) as                                      Decimal(15, 2)
            ) as PROCESSED_INVOICE,
            cast(
                sum(
                    case
                        when
                            (
                                B.IN_STATUS          = 'TOSAP'
                                and B.PAYMENT_STATUS = 'PAID'
                            )
                        then
                            1
                        else
                            0
                    end
                ) as                                      Decimal(15, 2)
            ) as PAID_INVOICE
        from my.VENDOR_MASTER as A
        inner join my.Invoice_Header as B
            on A.VENDOR_NO = B.SUPPLIER_ID
        where
                B.IN_STATUS     != 'deleted'
            and B.DOCUMENT_TYPE =  'RE'
        group by
            A.VENDOR_NO,
            B.CURRENCY,
            A.VENDOR_NAME,
            B.INVOICE_DATE,
            B.DUE_DATE,
            B.COMPANY_CODE,
            B.AMOUNT
        order by
            DUE_AMOUNT desc;
    //

    //api:liability-based-on-amount chart
    entity liability_based_on_amount       as
        select
            INVOICE_DATE,
            COMPANY_CODE,
            cast(
                year(INVOICE_DATE) as Integer
            ) as year,
            cast(
                sum(
                    case
                        when
                            IN_STATUS = 'tosap'
                        then
                            AMOUNT
                        else
                            0
                    end
                ) as                  Decimal(15, 2)
            ) as processed_amount,
            cast(
                sum(
                    case
                        when
                            IN_STATUS != 'tosap'
                            and (
                                DAYS_BETWEEN(
                                    BASELINE_DATE, CURRENT_DATE
                                ) < 0
                            )
                        then
                            AMOUNT
                        else
                            0
                    end
                ) as                  Decimal(15, 2)
            ) as op_overdue_amount,
            cast(
                sum(
                    case
                        when
                            IN_STATUS != 'tosap'
                            and (
                                DAYS_BETWEEN(
                                    BASELINE_DATE, CURRENT_DATE
                                ) >= 0
                            )
                        then
                            AMOUNT
                        else
                            0
                    end
                ) as                  Decimal(15, 2)
            ) as op_due_amount,
            cast(
                sum(
                    case
                        when
                            (
                                DAYS_BETWEEN(
                                    BASELINE_DATE, CURRENT_DATE
                                ) < 0
                            )
                        then
                            AMOUNT
                        else
                            0
                    end
                ) as                  Decimal(15, 2)
            ) as overdue_amount,
            cast(
                sum(
                    case
                        when
                            (
                                DAYS_BETWEEN(
                                    BASELINE_DATE, CURRENT_DATE
                                ) >= 0
                            )
                        then
                            AMOUNT
                        else
                            0
                    end
                ) as                  Decimal(15, 2)
            ) as due_amount
        from my.Invoice_Header
        where
                IN_STATUS     != 'deleted'
            and DOCUMENT_TYPE != 'RE' //  and year(INVOICE_DATE) = ? and company_code = ?"    ?$filter=year(INVOICE_DATE) eq 2023 and COMPANY_CODE eq '1000'
        group by
            INVOICE_DATE,
            COMPANY_CODE;


    entity vendorliability_based_on_amount as
        select
            B.VENDOR_NO,
            B.VENDOR_NAME,
            INVOICE_DATE,
            COMPANY_CODE,
            cast(
                year(INVOICE_DATE) as Integer
            ) as year,
            cast(
                sum(
                    A.AMOUNT
                ) as                  Decimal(15, 2)
            ) as TOTAL_AMOUNT,
            cast(
                sum(
                    case
                        when
                            A.IN_STATUS = 'TOSAP'
                        then
                            A.AMOUNT
                        else
                            0
                    end
                ) as                  Decimal(15, 2)
            ) as PROCESSED_AMOUNT,
            cast(
                sum(
                    case
                        when
                            (
                                DAYS_BETWEEN(
                                    A.BASELINE_DATE, CURRENT_DATE
                                ) < 0
                            )
                        then
                            A.AMOUNT
                        else
                            0
                    end
                ) as                  Decimal(15, 2)
            ) as OVERDUE_AMOUNT,
            cast(
                sum(
                    case
                        when
                            (
                                DAYS_BETWEEN(
                                    A.BASELINE_DATE, CURRENT_DATE
                                ) >= 0
                            )
                        then
                            A.AMOUNT
                        else
                            0
                    end
                ) as                  Decimal(15, 2)
            ) as DUE_AMOUNT
        from my.Invoice_Header as A
        inner join my.VENDOR_MASTER as B
            on A.SUPPLIER_ID = B.VENDOR_NO
        where
                A.IN_STATUS   != 'deleted'
            and DOCUMENT_TYPE != 'RE' // AND YEAR(A.INVOICE_DATE) = ? AND COMPANY_CODE = ?
        group by
            B.VENDOR_NO,
            B.VENDOR_NAME,
            INVOICE_DATE,
            COMPANY_CODE
        order by
            DUE_AMOUNT     desc,
            OVERDUE_AMOUNT desc
        limit 5;
//
};


service Masterservice {
    entity Master                          as projection on my.Master;
};
