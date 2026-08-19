"""
HR Analytics Project — EDA + Machine Learning
------------------------------------------------
Two models, both genuinely useful to an HR team:

1. ATTRITION PREDICTION (classification)
   RandomForestClassifier predicts which currently-employed people are
   likely to leave, with feature importances that explain *why*.

2. EMPLOYEE SEGMENTATION (unsupervised)
   KMeans clusters employees into personas using satisfaction,
   performance and tenure signals.

Outputs saved to ../docs/ and ../data/
"""

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import classification_report, roc_auc_score, confusion_matrix
from sklearn.cluster import KMeans

DATA = "../data/"
DOCS = "../docs/"

employees = pd.read_csv(DATA + "employees.csv")

# =========================================================
# PART 1 — EDA snapshot
# =========================================================
print("=" * 60)
print("EDA SUMMARY")
print("=" * 60)
print(f"Total employees: {len(employees)}")
print(f"Attrition rate: {(employees.Attrition=='Yes').mean()*100:.1f}%")
print("\nAttrition rate by department:")
dept_attr = employees.groupby("Department")["Attrition"].apply(lambda x: (x=="Yes").mean()*100).sort_values(ascending=False)
print(dept_attr.round(1))

plt.figure(figsize=(8, 5))
dept_attr.plot(kind="barh", color="#4C72B0")
plt.xlabel("Attrition Rate (%)")
plt.title("Attrition Rate by Department")
plt.tight_layout()
plt.savefig(DOCS + "attrition_by_department.png", dpi=150)
plt.close()

# =========================================================
# PART 2 — Attrition Prediction Model
# =========================================================
df = employees.copy()
target = (df["Attrition"] == "Yes").astype(int)

cat_cols = ["Gender", "MaritalStatus", "Department", "JobRole", "Education", "BusinessTravel", "OverTime"]
num_cols = ["Age", "TenureYears", "DistanceFromHomeKM", "MonthlyIncome", "YearsSinceLastPromotion",
            "NumCompaniesWorked", "WorkLifeBalance", "EnvironmentSatisfaction", "JobSatisfaction",
            "PerformanceRating", "TrainingTimesLastYear"]

X = df[cat_cols + num_cols].copy()
encoders = {}
for c in cat_cols:
    le = LabelEncoder()
    X[c] = le.fit_transform(X[c])
    encoders[c] = le

X_train, X_test, y_train, y_test = train_test_split(X, target, test_size=0.2, random_state=42, stratify=target)

model = RandomForestClassifier(
    n_estimators=300, max_depth=8, min_samples_leaf=5,
    class_weight="balanced", random_state=42
)
model.fit(X_train, y_train)

y_pred = model.predict(X_test)
y_proba = model.predict_proba(X_test)[:, 1]
auc = roc_auc_score(y_test, y_proba)
report = classification_report(y_test, y_pred, target_names=["Stayed", "Left"])
cm = confusion_matrix(y_test, y_pred)

with open(DOCS + "model_metrics.txt", "w") as f:
    f.write("HR ATTRITION PREDICTION MODEL — RandomForestClassifier\n")
    f.write("=" * 55 + "\n\n")
    f.write(f"ROC-AUC Score: {auc:.3f}\n\n")
    f.write("Classification Report:\n")
    f.write(report + "\n")
    f.write(f"Confusion Matrix:\n{cm}\n")

print(f"\nAttrition Model ROC-AUC: {auc:.3f}")
print(report)

importances = pd.Series(model.feature_importances_, index=X.columns).sort_values(ascending=True)
plt.figure(figsize=(8, 7))
importances.tail(12).plot(kind="barh", color="#DD8452")
plt.xlabel("Feature Importance")
plt.title("What Drives Attrition? (Random Forest Feature Importance)")
plt.tight_layout()
plt.savefig(DOCS + "feature_importance.png", dpi=150)
plt.close()

current = df[df["Attrition"] == "No"].copy()
X_current = current[cat_cols + num_cols].copy()
for c in cat_cols:
    X_current[c] = encoders[c].transform(X_current[c])
current["AttritionRiskScore"] = model.predict_proba(X_current)[:, 1]
current["RiskCategory"] = pd.cut(
    current["AttritionRiskScore"], bins=[0, 0.3, 0.6, 1.0],
    labels=["Low", "Medium", "High"]
)
at_risk = current[["EmployeeID", "Department", "JobRole", "MonthlyIncome", "AttritionRiskScore", "RiskCategory"]]
at_risk.sort_values("AttritionRiskScore", ascending=False).to_csv(DATA + "at_risk_employees.csv", index=False)
print(f"\nHigh-risk current employees flagged: {(current['RiskCategory']=='High').sum()}")

# =========================================================
# PART 3 — Employee Segmentation (KMeans)
# =========================================================
seg_features = ["TenureYears", "JobSatisfaction", "EnvironmentSatisfaction",
                 "WorkLifeBalance", "PerformanceRating", "MonthlyIncome"]
X_seg = df[seg_features].copy()
scaler = StandardScaler()
X_seg_scaled = scaler.fit_transform(X_seg)

kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
df["Segment"] = kmeans.fit_predict(X_seg_scaled)

profile = df.groupby("Segment")[seg_features].mean().round(2)
print("\nSegment profiles:\n", profile)

candidates = ["Stable Core", "High Performer / Flight Risk", "Disengaged", "Early-Career Builder"]
composite = pd.DataFrame({
    "tenure_rank": profile["TenureYears"].rank(),
    "perf_rank": profile["PerformanceRating"].rank(),
    "satisfaction_rank": profile["JobSatisfaction"].rank(),
})

segment_labels = {}
remaining_segments = list(profile.index)
remaining_labels = candidates.copy()

pick = composite.loc[remaining_segments, "tenure_rank"].idxmax()
segment_labels[pick] = "Stable Core"
remaining_segments.remove(pick); remaining_labels.remove("Stable Core")

sub = composite.loc[remaining_segments]
score = sub["perf_rank"] - sub["satisfaction_rank"]
pick = score.idxmax()
segment_labels[pick] = "High Performer / Flight Risk"
remaining_segments.remove(pick); remaining_labels.remove("High Performer / Flight Risk")

pick = composite.loc[remaining_segments, "satisfaction_rank"].idxmin()
segment_labels[pick] = "Disengaged"
remaining_segments.remove(pick); remaining_labels.remove("Disengaged")

segment_labels[remaining_segments[0]] = "Early-Career Builder"

df["SegmentLabel"] = df["Segment"].map(segment_labels)
df[["EmployeeID", "Department", "JobRole", "Segment", "SegmentLabel"]].to_csv(DATA + "employee_segments.csv", index=False)

plt.figure(figsize=(7, 6))
for seg_id, label in segment_labels.items():
    subset = df[df["Segment"] == seg_id]
    plt.scatter(subset["TenureYears"], subset["JobSatisfaction"] + np.random.normal(0, 0.08, len(subset)),
                label=label, alpha=0.5, s=18)
plt.xlabel("Tenure (Years)")
plt.ylabel("Job Satisfaction (jittered)")
plt.title("Employee Segments (KMeans, k=4)")
plt.legend(fontsize=8)
plt.tight_layout()
plt.savefig(DOCS + "employee_segments.png", dpi=150)
plt.close()

print("\nSegment sizes:")
print(df["SegmentLabel"].value_counts())
print(f"\nAll outputs saved to {DOCS} and {DATA}")