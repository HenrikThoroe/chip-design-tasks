#Importing Required Packages
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn import svm
from sklearn.metrics import confusion_matrix, classification_report
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split


wine = pd.read_csv('winequality-red.csv', sep = ';') #Update it with a valid path! 


bins = (2, 6.5, 8)  #Examine the impact of number of bins on the model accuracy 
group_names = ['bad', 'good']
wine['quality'] = pd.cut(wine['quality'], bins = bins, labels = group_names)


label_quality = LabelEncoder()


wine['quality']=label_quality.fit_transform(wine['quality'])
wine.head()
# Separate the dataset as response and farure
X = wine.drop('quality', axis = 1)
y = wine['quality']


#Train and test splitting of data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 20, random_state = 42)


# sc = StandardScaler()
# X_train = sc.fit_transform(X_train)
# X_test = sc.transform(X_test)


#Random Forest Classifier
rfc = RandomForestClassifier(max_depth = 3, n_estimators = 1)
rfc.fit(X_train, y_train)
pred_rfc = rfc.predict(X_test)


print (classification_report(y_test, pred_rfc))
#print (confusion_matrix(y_test, pred_rfc))


from sklearn.tree import plot_tree
import matplotlib.pyplot as plt

tree_to_plot = rfc.estimators_[0]

# Plot the decision tree
plt.figure(figsize=(25, 10))
plot_tree(tree_to_plot, feature_names=wine.columns.tolist(), filled=True, rounded=True, fontsize=10, class_names=True)
plt.title("Decision Tree from Random Forest")
plt.show()