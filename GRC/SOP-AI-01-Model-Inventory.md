# SOP-AI-01: Sovereign AI Model Inventory & Governance Policy

**Version:** 2026.1.0  
**Classification:** Internal / Sovereign AI Factory  
**Owner:** Infrastructure Architect  
**Status:** Active  

---

## 1. Purpose
This Standard Operating Procedure (SOP) establishes a formal registry and governance framework for all Large Language Models (LLMs) and Generative AI assets within the Sovereign AI Factory. The objective is to ensure model integrity, maintain hardware-to-workload mapping, and comply with **EU AI Act Article 12** regarding technical documentation and traceability.

## 2. Scope
This policy applies to all models hosted within **Zone B (AI Factory)**, including models served via NVIDIA Triton, vLLM, and LiteLLM.

## 3. Model Inventory (Current State)

| Model Identifier | Version/Branch | Quantization | VRAM Req. | Primary Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Llama-3-70B-Instruct** | Meta-Llama-3-70B | 4-bit (GGUF/EXL2) | ~40GB | Complex Reasoning / Agentic Tasks |
| **Mistral-12B-Instruct** | v0.3 | None (BF16) | ~24GB | High-Speed Inference / Tool Use |
| **Llama-Guard-3** | 8B | 8-bit | 8GB | Input/Output Safety Filtering |

## 4. Hardware Allocation Mapping
To ensure "High-Reliability" operations, models are pinned to specific GPU resources within the 6-GPU cluster to prevent resource contention.

* **Primary Inference (70B):** Spanned across GPU 0, 1, 2, and 3.
* **Secondary/Red Team Inference:** Assigned to GPU 4.
* **Safety/Guardrail Layer:** Assigned to GPU 5 (Shared with LiteLLM cache).

## 5. Model Change Management Procedure
Before any model is updated or a new model is introduced into the "Trust Zone," the following steps must be completed:

* **Integrity Verification:** Model weights must be hashed and compared against the source repository (e.g., Hugging Face) to prevent supply chain poisoning.
* **Performance Baselining:** Benchmarking must be conducted using vLLM or Triton to ensure the new model does not exceed the power/thermal thresholds of the 6-GPU host.
* **Security Probe:** The model must undergo an initial "Adversarial Sanity Check" using **Garak** in the Red Team Arena (VLAN 66).

## 6. Access Control & Auditability
* **Authentication:** All model access is gated by the LiteLLM Gateway and authenticated against **SOV-DC-01** (Active Directory).
* **Logging:** Every inference request is logged by **Wazuh** and **OpenSearch**. Logs must include the `model_name`, `request_hash`, and `timestamp`.
* **Transparency:** A monthly "Model Health & Usage" report is generated in **Grafana** for review.

## 7. Compliance Reference
* **NIST AI RMF:** Maps to Governance (GOV) and Map (MAP) functions.
* **EU AI Act:** Aligned with transparency requirements for high-impact general-purpose AI models.
