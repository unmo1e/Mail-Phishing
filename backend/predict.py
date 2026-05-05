from transformers import DistilBertForSequenceClassification, DistilBertTokenizer
import torch
import re

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = DistilBertForSequenceClassification.from_pretrained("./saved_model")
tokenizer = DistilBertTokenizer.from_pretrained("./saved_model")
model.to(device)

def clean_text(text):
    text = text.lower()
    text = re.sub(r'http\S+', 'url', text)
    text = re.sub(r'[^a-z\s]', '', text)
    return text

def predict_email(text):
    text = clean_text(text)
    inputs = tokenizer(
        text,
        return_tensors="pt",
        truncation=True,
        padding=True,
        max_length=128
    )
    inputs = {k: v.to(device) for k, v in inputs.items()}
    model.to(device)
    with torch.no_grad():
        outputs = model(**inputs)
        probs = torch.nn.functional.softmax(outputs.logits, dim=1)
        phishing_prob = probs[0][1].item()
        label = "Phishing" if phishing_prob > 0.5 else "Legitimate"
    return label, phishing_prob

print(predict_email("Your account has been suspended. Click here to verify immediately"))
