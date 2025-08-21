# routes/weather.py

from fastapi import APIRouter, HTTPException
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import time

# Router 생성
router = APIRouter()

@router.get("/weather")
async def get_weather():
    """
    다음 날씨 사이트에서 날씨 정보를 크롤링하여 반환합니다.
    """
    try:
        chrome_options = webdriver.ChromeOptions()
        chrome_options.add_argument("--headless")  # 창 안 띄우기
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        
        driver = webdriver.Chrome(
            service=Service(ChromeDriverManager().install()),
            options=chrome_options
        )
        
        driver.get("https://weather.daum.net/?location-regionId=AI10000901&weather-cp=kweather")
        time.sleep(2)  # 페이지 로딩 대기
        
        weathers = []
        
        try:
            xpath = '//*[@id="fc7ac7d4-ea2b-4850-bfd1-4f1ba87a03af"]/div/div/div[2]/div'
            elem = driver.find_element(By.XPATH, xpath)
            text = elem.text.strip()
            weathers.append({"title": text})
        except Exception as e:
            # XPath가 변경되었을 경우를 대비한 대안
            try:
                # 클래스나 다른 selector로 시도
                elem = driver.find_element(By.CSS_SELECTOR, "[data-testid='weather-summary']")
                text = elem.text.strip()
                weathers.append({"title": text})
            except:
                weathers.append({"title": "날씨 정보를 가져올 수 없습니다."})
                print(f"Weather scraping error: {e}")
        
        driver.quit()
        return {"results": weathers}
        
    except Exception as e:
        print(f"Weather API error: {e}")
        raise HTTPException(status_code=500, detail=f"날씨 정보를 가져오는데 실패했습니다: {str(e)}")