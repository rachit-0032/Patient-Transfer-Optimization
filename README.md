# Patient-Transfer-Optimization

## Introduction
Inter-hospital patient transfers (IHTs), most often undertaken to provide access to specialized care, comprise about 3.5% of all hospital inpatient admissions (1.5M admissions). Relocating patients to a hospital better suited for their care, this practice is crucial for delivering quality patient outcomes. Further, patient transfers maximize the impact of healthcare providers with unique expertise by providing them with cases that they are best equipped to handle. For these reasons, there exists a significant demand for private companies to provide patient transfer services to hospitals. This project takes the perspective of a fictitious inter-hospital patient transfer company based in Boston, Massachusetts.

## Problem Statement
Despite the clear benefits of IHTs, this practice also introduces additional risks and trade-offs. For example, even for non-emergency IHTs, there exists the possibility that the patient’s vital signs become unstable during transit. Further, the abrupt motion of the vehicle could lead to injury or discomfort for the patient, especially for patients with chronic pain. Patients also incur some of the costs of transfer, so patients of low socioeconomic status might elect to remain at a poorly equipped hospital for financial reasons.
The goal of this project is to reduce the direct costs of our fictitious company so that it can invest capital to mitigate the risks of patient transfer and reduce the transfer cost to patients. The hope is that this cost-reduction strategy will be adopted by real-life IHT companies, and the additional capital will result in better and more equitable outcomes for patients across all socioeconomic classes.

The cost reduction in our project was produced by using mixed-integer optimization methods to generate routes that reduce the total distance traveled among all transfer vehicles. According to a former colleague that worked at a real-life IHT company based in Charlotte, North Carolina, the standard procedure is to dispatch vehicles to transfer requests using simple, greedy approaches. This motivates clear opportunities of improvement using optimization.

Our [web dashboard](https://max-petruzzi.github.io/) displays the optimal routes for each vehicle given a pre-defined demand, both in the case of robustness to traffic and without traffic.

![Poster](https://github.com/rachit-0032/Patient-Transfer-Optimization/blob/main/Reports/Submission/15093_Poster_Image.png)

