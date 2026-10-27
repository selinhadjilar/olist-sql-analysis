# SQL Analysis of a Brazilian E-commerce Dataset

Six business questions answered with SQL in PostgreSQL, using the public Olist Brazilian e-commerce dataset (about 96,000 delivered orders, late 2016 to August 2018).

## Questions
1. How has monthly revenue grown?
2. Which states generate the most revenue?
3. Does late delivery lower review scores?
4. Which payment methods are used?
5. What is the repeat-customer rate?
6. How concentrated is customer spending?

## Key findings
- Revenue grew about 2.4x year on year (Jan–Aug 2018 vs Jan–Aug 2017), driven by more orders, not larger ones. 24 November 2017 (Black Friday) alone was about 15% of that month's revenue.
- São Paulo accounts for about 38% of revenue; the top three states about 63%.
- 8.1% of orders arrived late. Review scores fall from 4.29 (on time) to 1.73 (8+ days late).
- Credit cards carry about 78% of payment value.
- Only 3.0% of customers ordered more than once.
- The top 10% of customers account for 41% of revenue.

## Files
- `olist_analysis.sql`: table setup and every query, with comments

## Notes
- Revenue is item price in Brazilian reals (BRL), excluding freight, for delivered orders only.
- Results are descriptive; I did not test for statistical significance or causes.
- The data is not included. Download it from Kaggle ("Brazilian E-Commerce Public Dataset by Olist") and load it with the `\copy` commands in the SQL file.
- Findings are presented in an interactive Tableau dashboard: https://public.tableau.com/views/OlistE-commerceAnalysis_17931347125170/Dashboard1

## Tools
PostgreSQL, pgAdmin, psql
