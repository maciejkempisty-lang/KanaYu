extends RefCounted
## Port of fsrs Dart 2.0.1 (MIT, FSRS-LICENSE.txt), FSRS-6 default parameters.
## Same rounding, whole elapsed days, learning/relearning steps, no fuzzing.
const W = [0.2172,1.1771,3.2602,16.1507,7.0114,0.57,2.0966,0.0069,1.5261,0.112,1.0178,1.849,0.1133,0.3127,2.2934,0.2191,3.0004,0.7536,0.3332,0.1437,0.2]

static func initial_difficulty(rating: int) -> float:
	return clampf(W[4]-exp(W[5]*(rating-1))+1,1,10)

static func review(base: Dictionary, rating: int, now: float) -> Dictionary:
	var card := base.duplicate(true) if not base.is_empty() else {"state":1,"step":0,"stability":null,"difficulty":null,"last_review":null}
	var s: float = card.stability if card.stability != null else W[rating-1]
	var d: float = card.difficulty if card.difficulty != null else initial_difficulty(rating)
	if card.stability != null:
		var days := int((now-float(card.last_review))/86400.0)
		if days < 1:
			var increase := exp(W[17]*(rating-3+W[18]))*pow(s,-W[19])
			if rating >= 3: increase = maxf(increase,1.0)
			s = maxf(0.001,s*increase)
		else:
			var r := pow(1+(pow(0.9,-1.0/W[20])-1)*maxi(0,days)/s,-W[20])
			if rating == 1:
				s = minf(W[11]*pow(d,-W[12])*(pow(s+1,W[13])-1)*exp((1-r)*W[14]),s/exp(W[17]*W[18]))
			else:
				s *= 1+exp(W[8])*(11-d)*pow(s,-W[9])*(exp((1-r)*W[10])-1)*(W[15] if rating==2 else 1.0)*(W[16] if rating==4 else 1.0)
			s = maxf(0.001,s)
		d = clampf(W[7]*initial_difficulty(4)+(1-W[7])*(d+(10-d)*(-W[6]*(rating-3))/9.0),1,10)
	var interval := float(clampi(roundi(s),1,36500))*86400.0
	if card.state == 2:
		if rating == 1:
			card.state = 3
			card.step = 0
			interval = 600
	else:
		var steps := [60.0,600.0] if card.state == 1 else [600.0]
		if rating == 4 or (rating >= 2 and int(card.step)>=steps.size()) or (rating == 3 and int(card.step)+1==steps.size()):
			card.state = 2
			card.step = null
		elif rating == 1:
			card.step = 0
			interval = steps[0]
		elif rating == 2:
			interval = steps[int(card.step)]
			if card.step == 0: interval = steps[0]*1.5 if steps.size()==1 else (steps[0]+steps[1])/2
		else:
			card.step = int(card.step)+1
			interval = steps[int(card.step)]
	card.stability = s
	card.difficulty = d
	card.last_review = now
	card.due = now+interval
	return card
