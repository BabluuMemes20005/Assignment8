from flask import Flask, request, jsonify
import os

app = Flask(__name__)

@app.route('/submit', methods=['POST'])
def submit():
    data = request.json
    name = data.get("name")
    age = data.get("age")
    return jsonify({"message": f"Received data for {name}, age {age}."})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
