from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/')
def hello_world():
    return jsonify({
        'name': 'anton',
        'mail': 'anton@example.com'
    })

@app.route('/user', methods=['POST', 'GET'])
def signup():
	return jsonify({
		'email': request.form['email'],
		'nickname': request.form['nickname']
	}), 201

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
