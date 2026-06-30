import json
import random
from datetime import datetime, timedelta

def generate_dashboard_metrics():
    end_date = datetime.now()
    days = 15
    
    timeseries = []
    
    # Aggregated totals
    total_likes = 0
    total_passes = 0
    total_matches = 0
    total_success_matches = 0
    total_failed_matches = 0
    total_chat_accepted = 0
    
    total_relationships = 0
    total_pending = 0
    total_confirmed = 0
    total_declined = 0
    
    # Subscriptions (snapshot, typically doesn't aggregate by sum over days for total users, but let's simulate daily active subs)
    current_free = 45
    current_plus = 15
    current_premium = 20
    current_elite = 10
    
    # AI & Features (cumulative usage counts)
    total_self_reflection = 0
    total_couples_corner = 0
    total_conflict_resolution = 0
    total_ai_coach = 0

    for i in range(days):
        # Calculate date (from 15 days ago to today)
        current_date = end_date - timedelta(days=(days - 1 - i))
        date_str = current_date.strftime("%Y-%m-%d")
        
        # 1. Match & Interaction
        daily_likes = random.randint(200, 500)
        daily_passes = random.randint(300, 800)
        
        # matches are formed from likes
        daily_matches = int(daily_likes * random.uniform(0.15, 0.25))
        daily_success_matches = int(daily_matches * random.uniform(0.7, 0.9))
        daily_failed_matches = daily_matches - daily_success_matches
        
        daily_chat_accepted = int(daily_success_matches * random.uniform(0.5, 0.8))
        
        daily_latency = round(random.uniform(2.5, 15.0), 1) # minutes
        
        total_likes += daily_likes
        total_passes += daily_passes
        total_matches += daily_matches
        total_success_matches += daily_success_matches
        total_failed_matches += daily_failed_matches
        total_chat_accepted += daily_chat_accepted
        
        # 2. Relationship Metrics
        daily_relationships = int(daily_success_matches * random.uniform(0.1, 0.2))
        daily_confirmed = int(daily_relationships * random.uniform(0.4, 0.6))
        daily_declined = int(daily_relationships * random.uniform(0.1, 0.3))
        daily_pending = daily_relationships - daily_confirmed - daily_declined
        
        total_relationships += daily_relationships
        total_confirmed += daily_confirmed
        total_declined += daily_declined
        total_pending += daily_pending
        
        # 3. Subscriptions (simulate slight growth)
        if random.random() > 0.5: current_free += random.randint(0, 2)
        if random.random() > 0.7: current_plus += random.randint(0, 1)
        if random.random() > 0.7: current_premium += random.randint(0, 1)
        if random.random() > 0.8: current_elite += random.randint(0, 1)
        
        daily_total_users = current_free + current_plus + current_premium + current_elite
        
        # 4. Feature Usage (AI & Healing)
        daily_self_reflection = random.randint(10, 30)
        daily_couples_corner = random.randint(5, 15)
        daily_conflict = random.randint(2, 10)
        daily_ai_coach = random.randint(15, 40)
        
        total_self_reflection += daily_self_reflection
        total_couples_corner += daily_couples_corner
        total_conflict_resolution += daily_conflict
        total_ai_coach += daily_ai_coach
        
        timeseries.append({
            "date": date_str,
            "matchMetrics": {
                "likesCount": daily_likes,
                "passesCount": daily_passes,
                "totalMatches": daily_matches,
                "successMatches": daily_success_matches,
                "failedMatches": daily_failed_matches,
                "successRate": round((daily_success_matches / daily_matches * 100) if daily_matches > 0 else 0, 2),
                "chatAcceptedMatches": daily_chat_accepted,
                "chatConversionRate": round((daily_chat_accepted / daily_success_matches * 100) if daily_success_matches > 0 else 0, 2),
                "responseLatencyMinutes": daily_latency
            },
            "relationshipMetrics": {
                "totalRelationships": daily_relationships,
                "relationshipPending": daily_pending,
                "relationshipConfirmed": daily_confirmed,
                "relationshipDeclined": daily_declined
            },
            "subscriptionMetrics": {
                "freeSubsCount": current_free,
                "plusSubsCount": current_plus,
                "premiumSubsCount": current_premium,
                "eliteSubsCount": current_elite,
                "premiumRate": round(((current_plus + current_premium + current_elite) / daily_total_users * 100) if daily_total_users > 0 else 0, 2)
            },
            "featureUsage": {
                "selfReflectionCorner": daily_self_reflection,
                "couplesCorner": daily_couples_corner,
                "conflictResolution": daily_conflict,
                "aiCoachChat": daily_ai_coach
            }
        })
        
    # Calculate Summary
    total_users_end = current_free + current_plus + current_premium + current_elite
    total_paid = current_plus + current_premium + current_elite
    
    total_ai_interactions = total_self_reflection + total_couples_corner + total_conflict_resolution + total_ai_coach
    ai_adoption_rate = round((total_ai_interactions / (total_users_end * 15)) * 100, 2) # simplified logic
    
    summary = {
        "period": "Last 15 Days",
        "matchMetrics": {
            "totalLikes": total_likes,
            "totalPasses": total_passes,
            "totalMatches": total_matches,
            "successMatches": total_success_matches,
            "failedMatches": total_failed_matches,
            "successRate": round((total_success_matches / total_matches * 100) if total_matches > 0 else 0, 2),
            "chatAcceptedMatches": total_chat_accepted,
            "chatConversionRate": round((total_chat_accepted / total_success_matches * 100) if total_success_matches > 0 else 0, 2),
            "averageResponseLatencyMinutes": 5.4
        },
        "relationshipMetrics": {
            "totalRelationships": total_relationships,
            "relationshipPending": total_pending,
            "relationshipConfirmed": total_confirmed,
            "relationshipDeclined": total_declined
        },
        "subscriptionMetrics": {
            "freeSubsCount": current_free,
            "plusSubsCount": current_plus,
            "premiumSubsCount": current_premium,
            "eliteSubsCount": current_elite,
            "premiumRate": round((total_paid / total_users_end * 100) if total_users_end > 0 else 0, 2)
        },
        "featureUsage": {
            "courseCompletionRate": round(random.uniform(60.0, 85.0), 2),
            "aiAdoptionRate": min(ai_adoption_rate, 100.0),
            "breakdown": {
                "selfReflectionCorner": total_self_reflection,
                "couplesCorner": total_couples_corner,
                "conflictResolution": total_conflict_resolution,
                "aiCoachChat": total_ai_coach
            }
        }
    }
    
    output_data = {
        "summary": summary,
        "timeseries": timeseries
    }
    
    with open('dashboard_metrics_15_days.json', 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=4)
        
    print("Generated dashboard_metrics_15_days.json successfully.")

if __name__ == "__main__":
    generate_dashboard_metrics()
