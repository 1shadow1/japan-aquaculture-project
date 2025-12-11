#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
路由决策智能体 - 参考 cognitive_model/agents/routing_agent.py
"""
import logging
from typing import Dict, Any, List, Optional

from .llm_utils import execute_llm_call, LLMConfig, format_messages_for_llm, format_config_for_llm
from langchain_core.messages import HumanMessage

logger = logging.getLogger(__name__)


class RoutingAgent:
    """
    路由决策智能体
    
    负责决定处理用户请求的最佳路径（是否需要工具、需要哪些工具等）
    """
    
    def __init__(self):
        """初始化路由决策智能体"""
        pass
    
    async def route_decision(
        self,
        user_input: str,
        intent: str,
        context: Optional[Dict[str, Any]] = None,
        model_config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        做出路由决策
        
        Args:
            user_input: 用户输入
            intent: 识别的意图
            context: 上下文信息
            model_config: 模型配置
            
        Returns:
            dict: 路由决策结果
        """
        system_prompt = """你是一个路由决策专家。根据用户意图和输入，决定处理路径。

决策选项：
1. 直接回答：简单查询，可以直接回答
2. 数据库查询：需要查询数据库获取数据
3. 数据分析：需要对数据进行复杂分析
4. 工具调用：需要使用特定工具（如设备控制）

请返回JSON格式：
{
    "decision": "直接回答|数据库查询|数据分析|工具调用",
    "reason": "决策理由",
    "tools": ["工具名称列表，如果需要"],
    "needs_data": true/false
}
"""
        
        context_str = ""
        if context:
            context_str = f"\n上下文信息：{context}"
        
        user_prompt = f"""用户意图：{intent}
用户输入：{user_input}{context_str}

请做出路由决策。"""
        
        config = format_config_for_llm(model_config)
        messages = format_messages_for_llm(system_prompt)
        messages.append(HumanMessage(content=user_prompt))
        
        try:
            response_content, stats = await execute_llm_call(messages, config)
            
            # 尝试解析 JSON（简化版，实际应该用 json.loads）
            import json
            try:
                decision = json.loads(response_content)
            except:
                # 如果解析失败，使用默认决策
                decision = {
                    "decision": "直接回答",
                    "reason": "无法解析路由决策",
                    "tools": [],
                    "needs_data": False
                }
            
            logger.info(f"路由决策: {decision.get('decision')}")
            return decision
            
        except Exception as e:
            logger.error(f"路由决策失败: {e}", exc_info=True)
            return {
                "decision": "直接回答",
                "reason": f"路由决策失败: {str(e)}",
                "tools": [],
                "needs_data": False
            }

